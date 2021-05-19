import Foundation

final class MeetingCreatingRepository: NSObject, MeetingCreatingRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private let sdk = MEGASdkManager.sharedMEGASdk()

    func setChatVideoInDevices(device: String) {
        chatSdk.setChatVideoInDevices(device)
    }
    
    func openVideoDevice() {
        chatSdk.openVideoDevice()
    }
    
    func videoDevices() -> [String] {
        chatSdk.chatVideoInDevices()?.toArray() ?? []
    }
    
    func releaseDevice() {
        chatSdk.releaseVideoDevice()
    }
    
    func getUsername() -> String {
        let user = MEGAStore.shareInstance().fetchUser(withEmail: sdk.myEmail)
        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }
        
        return chatSdk.userFullnameFromCache(byUserHandle:  sdk.myUser?.handle ?? 0) ?? ""

    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        guard let call = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return CallEntity(with: call)
    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(request.chatHandle)")
                return
            }
            self?.chatSdk.startChatCall(chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatStartCallRequestDelegate(completion: { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        completion(.failure(.generic))
                        return
                    }
                    completion(.success(ChatRoomEntity(with: chatroom)))
                } else {
                    completion(.failure(.generic))
                }
            }))

        }
        
        chatSdk.createMeeting(withTitle: meetingName, delegate: delegate)
    }

    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
       chatSdk.addChatLocalVideo(123, delegate: delegate)
    }

    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(request.chatHandle)")
                completion(.failure(.generic))
                return
            }

            self?.chatSdk.answerChatCall(chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatAnswerCallRequestDelegate { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        completion(.failure(.generic))
                        return
                    }
                    completion(.success(ChatRoomEntity(with: chatroom)))
                } else {
                    completion(.failure(.generic))
                }
            })
        }
        chatSdk.autojoinPublicChat(chatId, delegate: delegate)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        guard let url = URL(string: link) else {
            completion(.failure(.generic))
            return
        }
        
        chatSdk.checkChatLink(url, delegate: MEGAChatGenericRequestDelegate(completion: { [weak self] (request, error) in
          
            guard (error.type == .MEGAChatErrorTypeOk || error.type == .MegaChatErrorTypeExist) else {
                completion(.failure(.generic))
                return
            }
            
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                MEGALogDebug("ChatRoom not found with chat handle \(request.chatHandle)")
                completion(.failure(.generic))
                return
            }
            completion(.success(ChatRoomEntity(with: chatroom)))
            
        }))
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, completion: @escaping (Result<MEGARequest, MEGASDKErrorType>) -> Void) {
        sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: MEGAResultRequestDelegate { (result) in
            switch result {
            case .failure(let errorType):
                completion(.failure(errorType))
            case .success(let request):
                completion(.success(request))
            }
        })
    }
}
