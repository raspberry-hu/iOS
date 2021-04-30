import XCTest
@testable import MEGA

final class MeetingContainerViewModelTests: XCTestCase {

    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), callManagerUseCase: MockCallManagerUseCase())
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.showMeetingUI_calledTimes == 1)
    }
    
    func testAction_hangCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, callManagerUseCase: callManagerUserCase)
        test(viewModel: viewModel, action: .hangCall, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_backButtonTap() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), callManagerUseCase: MockCallManagerUseCase())
        test(viewModel: viewModel, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_ChangeMenuVisibility() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), callManagerUseCase: MockCallManagerUseCase())
        test(viewModel: viewModel, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(router.toggleFloatingPanel_CalledTimes == 1)
    }

}

final class MockMeetingContainerRouter: MeetingContainerRouting {
    var showMeetingUI_calledTimes = 0
    var dismiss_calledTimes = 0
    var toggleFloatingPanel_CalledTimes = 0

    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
}

