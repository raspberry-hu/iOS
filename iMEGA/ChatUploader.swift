

@objc class ChatUploader: NSObject {
    @objc static let sharedInstance = ChatUploader()
    
    private let store = MEGAStore.shareInstance()
    
    private var isDatabaseCleanupTaskCompleted: Bool?
    private let uploaderQueue = DispatchQueue(label: "ChatUploaderQueue")

    private override init() { super.init() }
    
    @objc func setup() {
        isDatabaseCleanupTaskCompleted = false
        MEGASdkManager.sharedMEGASdk().add(self)
    }
    
    @objc func upload(image: UIImage, chatRoomId: UInt64) {
        MyChatFilesFolderNodeAccess.shared.loadNode { myChatFilesFolderNode, error in
            guard let myChatFilesFolderNode = myChatFilesFolderNode else {
                if let error = error {
                    MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
                }
                return
            }
            if let data = image.jpegData(compressionQuality: CGFloat(0.7)) {
                let fileName = "\(NSDate().mnz_formattedDefaultNameForMedia()).jpg"
                let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                do {
                    try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                    var appData = NSString().mnz_appData(toSaveCoordinates: tempPath.mnz_coordinatesOfPhotoOrVideo() ?? "")
                    appData = ((appData) as NSString).mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: false)
                    ChatUploader.sharedInstance.upload(filepath: tempPath,
                                                       appData: appData,
                                                       chatRoomId: chatRoomId,
                                                       parentNode: myChatFilesFolderNode,
                                                       isSourceTemporary: false,
                                                       delegate: MEGAStartUploadTransferDelegate(completion: nil))
                    
                } catch {
                    MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func upload(filepath: String,
                      appData: String,
                      chatRoomId: UInt64,
                      parentNode: MEGANode,
                      isSourceTemporary: Bool,
                      delegate: MEGAStartUploadTransferDelegate) {
        
        MEGALogInfo("[ChatUploader] uploading File path \(filepath)")
        cleanupDatabaseIfRequired()
        guard let context = store.stack.newBackgroundContext() else { return }
        
        context.performAndWait {
            MEGALogInfo("[ChatUploader] inserted new entry File path \(filepath)")
            // insert into database only if the duplicate path does not exsist - "allowDuplicateFilePath" parameter
//            self.store.insertChatUploadTransfer(withFilepath: filepath,
//                                                chatRoomId: String(chatRoomId),
//                                                transferTag: nil,
//                                                allowDuplicateFilePath: false,
//                                                context: context)
            //UInt64修改
            do {
                try self.store.insertChatUploadTransfer(withFilepath: filepath,
                                                    chatRoomId: String(chatRoomId),
                                                    transferTag: nil,
                                                    allowDuplicateFilePath: false,
                                                    context: context)
            } catch let error as NSError {
                print("UInt64修改失败: \(error.localizedDescription)")
            }
            //
            
            MEGALogInfo("[ChatUploader] SDK upload started for File path \(filepath)")
            MEGASdkManager.sharedMEGASdk().startUploadForChat(withLocalPath: filepath,
                                                              parent: parentNode,
                                                              appData: appData,
                                                              isSourceTemporary: isSourceTemporary,
                                                              delegate: delegate)
        }
    }
    
    private func cleanupDatabaseIfRequired() {
        if let isDatabaseCleanupTaskCompleted = isDatabaseCleanupTaskCompleted,
           !isDatabaseCleanupTaskCompleted {
            self.isDatabaseCleanupTaskCompleted = true
            cleanupDatabase()
        }
    }
    
    private func cleanupDatabase() {
        guard let context = store.stack.newBackgroundContext() else  { return }
        
        context.performAndWait {
            let transferList = MEGASdkManager.sharedMEGASdk().transfers
            MEGALogDebug("[ChatUploader] transfer list count : \(transferList.size.intValue)")
            let sdkTransfers = (0..<transferList.size.intValue).compactMap { transferList.transfer(at: $0) }
            self.store.fetchAllChatUploadTransfer(context: context).forEach { transfer in
                if transfer.nodeHandle == nil {
                    MEGALogDebug("[ChatUploader] transfer task not completed \(transfer.index) : \(transfer.filepath)")
                    
                    let foundTransfers = sdkTransfers.filter({
                        return $0.path == transfer.filepath
                    })
                    
                    if !foundTransfers.isEmpty {
                        transfer.transferTag = nil
                        MEGALogDebug("[ChatUploader] transfer tag set to nil at \(transfer.index) : \(transfer.filepath)")
                    } else {
                        context.delete(transfer)
                        MEGALogDebug("[ChatUploader] Deleted the transfer task \(transfer.index) : \(transfer.filepath)")
                    }
                } else {
                    MEGALogDebug("[ChatUploader] transfer task is already completed \(transfer.index) : \(transfer.filepath)")
                }
            }
            
            self.store.save(context)
        }
    }
    
    private func updateDatabase(withChatRoomIdString chatRoomIdString: String, context: NSManagedObjectContext) {
        context.performAndWait {
            let allTransfers = store.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context)
            allTransfers.forEach { transfer in
                MEGALogInfo("[ChatUploader] transfer index \(transfer.index) with file path \(transfer.filepath)")
            }
            let index = allTransfers.firstIndex(where: { $0.nodeHandle == nil })
            MEGALogInfo("[ChatUploader] transfer found at index \(index ?? -1)")
            if let totalIndexes = (index == nil) ? allTransfers.count : index {
                (0..<totalIndexes).forEach { index in
                    let transfer = allTransfers[index]
                    if let handle = transfer.nodeHandle,
                       let nodeHandle = UInt64(handle),
                       let chatRoomId = UInt64(chatRoomIdString) {
                        
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()

                        let requestDelegate = MEGAChatAttachNodeRequestDelegate { _, _ in
                            dispatchGroup.leave()
                        }
                        if let appData = transfer.appData, appData.contains("attachVoiceClipToChatID") {
                            MEGASdkManager.sharedMEGAChatSdk().attachVoiceMessage(toChat: chatRoomId, node: nodeHandle, delegate: requestDelegate)
                        } else {
                            MEGASdkManager.sharedMEGAChatSdk().attachNode(toChat: chatRoomId, node: nodeHandle, delegate: requestDelegate)
                        }
                        
                        MEGALogInfo("[ChatUploader] attachment complete File path \(transfer.filepath)")
                        context.delete(transfer)
                        dispatchGroup.wait()
                    }
                }
                
                store.save(context)
            }
        }
    }
}

extension ChatUploader: MEGATransferDelegate {
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        uploaderQueue.async {
            guard transfer.type == .upload,
                  let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
                  let context = self.store.stack.newBackgroundContext() else {
                return
            }
            
            self.cleanupDatabaseIfRequired()
            
            context.performAndWait {
                let allTransfers = self.store.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context)
                if let transferTask = allTransfers.filter({ $0.filepath == transfer.path && ($0.transferTag == nil || $0.transferTag == String(transfer.tag))}).first {
                    transferTask.transferTag = String(transfer.tag)
                    MEGALogInfo("[ChatUploader] updating existing row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                } else {
                    self.store.insertChatUploadTransfer(withFilepath: transfer.path,
                                                        chatRoomId: chatRoomIdString,
                                                        transferTag: String(transfer.tag),
                                                        allowDuplicateFilePath: true,
                                                        context: context)
                    MEGALogInfo("[ChatUploader] inserting a new row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                }
                
                self.store.save(context)
            }
        }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        uploaderQueue.async {
            guard transfer.type == .upload,
                  let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
                  let context = self.store.stack.newBackgroundContext() else {
                return
            }
            
            if (error.type == .apiEExist) {
//                self.store.deleteChatUploadTransfer(withChatRoomId: chatRoomIdString,
//                                               transferTag: String(transfer.tag),
//                                               context: context)
                //UInt64修改
                do {
                    try self.store.deleteChatUploadTransfer(withChatRoomId: chatRoomIdString,
                                                            transferTag: String(transfer.tag),
                                                            context: context)
                } catch let error as NSError {
                    print("UInt64修改失败: \(error.localizedDescription)")
                }
                //
                MEGALogInfo("[ChatUploader] transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
                return;
            }
            
            MEGALogInfo("[ChatUploader] upload complete File path \(transfer.path ?? "No file path found")")
            
            transfer.mnz_moveFileToDestinationIfVoiceClipData()
            context.performAndWait {
//                self.store.updateChatUploadTransfer(filepath: transfer.path,
//                                                    chatRoomId: chatRoomIdString,
//                                                    nodeHandle: String(transfer.nodeHandle),
//                                                    transferTag: String(transfer.tag),
//                                                    appData: transfer.appData,
//                                                    context: context)
                //UInt64修改
                            do {
                                try self.store.updateChatUploadTransfer(filepath: transfer.path,
                                                                                    chatRoomId: chatRoomIdString,
                                                                                    nodeHandle: String(transfer.nodeHandle),
                                                                                    transferTag: String(transfer.tag),
                                                                                    appData: transfer.appData,
                                                                                    context: context)
                            } catch let error as NSError {
                                print("UInt64修改失败: \(error.localizedDescription)")
                            }
                //
                self.updateDatabase(withChatRoomIdString: chatRoomIdString, context: context)
            }
        }
    }
    
}

