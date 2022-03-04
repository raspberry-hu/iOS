import UIKit
import CoreServices

protocol HomeRouterProtocol {

    func didTap(on source: HomeRoutingSource, with object: Any?)
    
    func showFavourites(navigationController: UINavigationController, homeViewController: HomeViewController, slidePanelView: SlidePanelView)
    
    func showNode(_ base64Handle: MEGABase64Handle)
}

enum HomeRoutingSource {

    // MARK: - Navigation Bar Button

    case avatar
    case uploadButton
    case newChat

    // MARK: - Application Root Launcher

    case showAchievement

    // MARK: - Recents

    case nodeCustomActions(MEGANode)
    case node(MEGANode)

    // MARK: - Node Actions

    case fileInfo(MEGANode)
    case linkManagement(MEGANode)
    case removeLink(MEGANode)
    case copy(MEGANode)
    case move(MEGANode)
    case delete(MEGANode)
    case share(MEGANode, Any?)
    case shareFolder(MEGANode)
    case manageShare(MEGANode)
    case setLabel(MEGANode)
    case editTextFile(MEGANode)
    case viewTextFileVersions(MEGANode)
    //MARK: mint
//    case mint(MEGANode)
}

final class HomeRouter: HomeRouterProtocol {

    // MARK: - Navigations

    private weak var navigationController: UINavigationController?

    private weak var tabBarController: MainTabBarController?

    // MARK: - Sub-router

    private let newChatRouter: NewChatRouter

    // MARK: - Node Action Routers

    private let nodeActionRouter: RecentNodeRouter

    private let nodeInfoRouter: NodeInfoRouter

    private let nodeLinkManagementRouter: NodeLinkRouter

    private let nodeManageRouter: NodeManagementRouter

    private let nodeShareRouter: NodeShareRouter

    // MARK: - Lifecycles

    init(navigationController: UINavigationController?, tabBarController: MainTabBarController) {
        assert(navigationController != nil, "Must pass in a UINavigationController in HomeRouter.")
        self.navigationController = navigationController
        self.newChatRouter = NewChatRouter(navigationController: navigationController, tabBarController: tabBarController)
        self.nodeActionRouter = RecentNodeRouter(navigationController: navigationController)
        self.nodeInfoRouter = NodeInfoRouter(navigationController: navigationController)
        self.nodeLinkManagementRouter = NodeLinkRouter(navigationController: navigationController)
        self.nodeManageRouter = NodeManagementRouter(navigationController: navigationController)
        self.nodeShareRouter = NodeShareRouter(navigationController: navigationController)
    }

    func didTap(on source: HomeRoutingSource, with object: Any? = nil) {
        switch source {

        //MARK: mint
        case .avatar:
            routeToAccount(with: navigationController)
        case .uploadButton:
            presentUploadOptionActionSheet(from: navigationController, withActionItems: object as! [ActionSheetAction])
        // MARK: - New Chat

        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)

        // MARK: - Application

        case .showAchievement:
            presentAchievement()

        // MARK: - Recents

        case .nodeCustomActions(let node):
            nodeActionRouter.didTap(.nodeActions(node), object: object)
        case .node:
            break

        // MARK: - Node Actions

        case .fileInfo(let node):
            nodeInfoRouter.showInformation(for: node)
        case .viewTextFileVersions(let node):
            nodeInfoRouter.showVersions(for: node)
        case .linkManagement(let node):
            nodeLinkManagementRouter.showLinkManagement(for: node)
        case .removeLink(let node):
            nodeLinkManagementRouter.showRemoveLink(for: node)

        // MARK: - Node Copy & Move & Delete & Edit
        case .copy(let node):
            nodeManageRouter.showCopyDestination(for: node)
        case .move(let node):
            nodeManageRouter.showMoveDestination(for: node)
        case .delete(let node):
            nodeManageRouter.showMoveToRubbishBin(for: node)
        case .setLabel(let node):
            print("颜色测试1")
            nodeManageRouter.showLabelColorAction(for: node)
        case .editTextFile(let node):
            nodeManageRouter.showEditTextFile(for: node)

        // MARK: - Share
        case .share(let node, let sender):
            nodeShareRouter.showSharing(for: node, sender: sender)
        case .shareFolder(let node):
            nodeShareRouter.showSharingFolder(for: node)
        case .manageShare(let node):
            nodeShareRouter.showManageSharing(for: node)
        }
    }
    
    func showFavourites(navigationController: UINavigationController, homeViewController: HomeViewController, slidePanelView: SlidePanelView) {
        FavouritesRouter(navigationController: self.navigationController ?? UINavigationController(), homeViewController: homeViewController, slidePanelView: slidePanelView).start()
    }
    
    func showNode(_ base64Handle: MEGABase64Handle) {
        navigationController?.popToRootViewController(animated: false)
        let handle = MEGASdk.handle(forBase64Handle: base64Handle)
        NodeOpener(navigationController: navigationController).openNode(handle)
    }
    
    // MARK: - Show Photos Explorer View Controller
    
    func photosExplorerSelected() {
        PhotosExplorerRouter(navigationController: navigationController, explorerType: .photo).start()
    }
    
    // MARK: - Show Documents Explorer View Controller
    
    func documentsExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .document).start()
    }
    
    // MARK: - Show Audio Explorer View Controller
    
    func audioExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .audio).start()
    }
    
    // MARK: - Show Audio Explorer View Controller
    
    func videoExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .video).start()
    }
    
    // MARK: - Show Account View Controller

    private func routeToAccount(with navigationController: UINavigationController?) {
        let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
            .instantiateViewController(withIdentifier: "MyAccountHall")
        navigationController?.pushViewController(myAccountViewController, animated: true)
    }

    // MARK: - Display Upload Source Selection Action Sheet

    private func presentUploadOptionActionSheet(
        from navigationController: UINavigationController?,
        withActionItems actions: [ActionSheetAction]
    ) {
        let actionSheetViewController = ActionSheetViewController(actions: actions,
                                                                  headerTitle: nil,
                                                                  dismissCompletion: nil,
                                                                  sender: nil)
        navigationController?.present(actionSheetViewController, animated: true, completion: nil)
    }

    // MARK: - Display Application Event

    private func presentAchievement() {
        guard let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
                .instantiateViewController(withIdentifier: "MyAccountHall") as? MyAccountHallViewController else {
            return
        }
        navigationController?.pushViewController(myAccountViewController, animated: true)
        myAccountViewController.openAchievements()
    }
}
