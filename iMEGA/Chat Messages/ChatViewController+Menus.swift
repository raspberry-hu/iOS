
import Foundation

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        if megaMessage.type == .normal || megaMessage.type == .containsMeta {
            if let content = megaMessage.content {
                UIPasteboard.general.string = content
            }
        } else if megaMessage.type == .attachment {
            if megaMessage.nodeList.size.uintValue == 1,
               let node = megaMessage.nodeList.node(at: 0),
               let name = node.name,
               name.mnz_isImagePathExtension {
                let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
                let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")
                if FileManager.default.fileExists(atPath: originalImagePath), let originalImage = UIImage(contentsOfFile: originalImagePath) {
                    UIPasteboard.general.image = originalImage
                } else if FileManager.default.fileExists(atPath: previewFilePath), let previewImage = UIImage(contentsOfFile: previewFilePath) {
                    UIPasteboard.general.image = previewImage
                }
            }
        }
    }
    
    func forwardMessage(_ message: ChatMessage) {
        selectedMessages.insert(message)
        customToolbar(type: .text)
        setEditing(true, animated: true)
        
        guard let index = messages.firstIndex(where: { chatMessage -> Bool in
            guard let chatMessage = chatMessage as? ChatMessage else {
                return false
            }
            return message == chatMessage
        }) else { return }
        
        messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .centeredVertically, animated: true)
        
    }
    
    func editMessage(_ message: ChatMessage) {
        editMessage = message
        if message.message.containsMeta?.type == MEGAChatContainsMetaType.geolocation {
            self.presentShareLocation(editing: true)
        } else {
            guard let content = editMessage?.message.content else {
                return
            }
            chatInputBar?.set(text: content)
        }
    }
    
    func deleteMessage(_ chatMessage: ChatMessage) {
        
        let megaMessage =  chatMessage.message
        
        if megaMessage.type == .attachment ||
            megaMessage.type == .voiceClip {
            if audioController.playingMessage?.messageId == chatMessage.messageId {
                if audioController.state == .playing {
                    audioController.stopAnyOngoingPlaying()
                }
            }
            MEGASdkManager.sharedMEGAChatSdk().revokeAttachmentMessage(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
        } else {
            let foundIndex = messages.firstIndex { message -> Bool in
                guard let localChatMessage = message as? ChatMessage else {
                    return false
                }
                
                return chatMessage == localChatMessage
            }
            
            guard let index = foundIndex else {
                return
            }
            
            if megaMessage.status == .sending {
                chatRoomDelegate.chatMessages.remove(at: index)
                messagesCollectionView.performBatchUpdates({
                    messagesCollectionView.deleteSections([index])
                }, completion: nil)
            } else {
                let messageId = megaMessage.status == .sending ? megaMessage.temporalId : megaMessage.messageId
                let deleteMessage = MEGASdkManager.sharedMEGAChatSdk().deleteMessage(forChat: chatRoom.chatId, messageId: messageId)
                deleteMessage?.chatId = chatRoom.chatId
                chatRoomDelegate.chatMessages[index] = ChatMessage(message: deleteMessage!, chatRoom: chatRoom)
            }
        }
        
    }
    
    func removeRichPreview(_ message: ChatMessage) {
        let megaMessage =  message.message
        MEGASdkManager.sharedMEGAChatSdk().removeRichLink(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
    }
    
    func downloadMessage(_ messages: [ChatMessage]) {
        var downloading = false
        
        for message in messages {
            let megaMessage =  message.message
            
            for index in 0..<megaMessage.nodeList.size.intValue {
                var node = megaMessage.nodeList.node(at: index)
                if chatRoom.isPreview {
                    node = sdk.authorizeNode(megaMessage.nodeList.node(at: index))
                }
                
                if let node = node {
                    Helper.downloadNode(node, folderPath: Helper.relativePathForOffline(), isFolderLink: false)
                    downloading = true
                }
            }
        }
        
        if downloading {
            SVProgressHUD.show(Asset.Images.Hud.hudDownload.image, status: Strings.Localizable.downloadStarted)
        }
    }
    
    func importMessage(_ messages: [ChatMessage]) {

        var nodes = [MEGANode]()
        
        for message in messages {
            let megaMessage = message.message
            for index in 0..<megaMessage.nodeList.size.intValue {
                var node = megaMessage.nodeList.node(at: index)
                if chatRoom.isPreview {
                    node = sdk.authorizeNode(megaMessage.nodeList.node(at: index))
                }
                if let node = node {
                    nodes.append(node)
                }
            }
        }
        
        let navigationController = UIStoryboard.init(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        
        let browserVC = navigationController.viewControllers.first as! BrowserViewController
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = .import
        
        present(viewController: navigationController)
        
    }
    
    func addContactMessage(_ message: ChatMessage) {
        let megaMessage =  message.message

        let usersCount = megaMessage.usersCount
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: usersCount)
        for index in 0..<usersCount {
            if let email = megaMessage.userEmail(at: index) {
                sdk.inviteContact(withEmail: email, message: "", action: .add, delegate: inviteContactRequestDelegate)
            }
        }
        
    }
    
    func saveToPhotos(_ messages: [ChatMessage]) {
        for chatMessage in messages {
            if chatMessage.message.nodeList.size.uintValue == 1,
               var node = chatMessage.message.nodeList.node(at: 0),
               let name = node.name,
               (name.mnz_isVisualMediaPathExtension) {
                if chatRoom.isPreview,
                   let authorizedNode = sdk.authorizeChatNode(node, cauth: chatRoom.authorizationToken)  {
                    node = authorizedNode
                }
                print("照片11")
                node.mnz_saveToPhotos()
            } else {
                MEGALogDebug("Wrong Message type to be saved to album")
            }
        }
    }
    
    func select(_ chatMessage: ChatMessage) {
        forwardMessage(chatMessage)
    }
}
