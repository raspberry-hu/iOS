import UIKit

class MeetingJoinAlertViewController: UIAlertController {

    // MARK: - Internal properties
    var viewModel: MeetingJoinViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        // Do any additional setup after loading the view.
    }
    
    private func configure() {
        title = NSLocalizedString("Enter Meeting Link", comment: "")

        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { (action) in
           
        }
        addAction(cancelAction)

        let joinAction = UIAlertAction(title: NSLocalizedString("join", comment: ""), style: .default) { [weak self] (action) in
            guard let link = self?.textFields?.first?.text else { return }
            self?.viewModel.dispatch(.didTapJoinButton(link))
        }
        addAction(joinAction)
        
        addTextField { [weak self] textfield in
            textfield.delegate = self
        }
        
    }
}

extension MeetingJoinAlertViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let menuController = UIMenuController.shared
        menuController.setMenuVisible(true, animated: true)
    }
}
