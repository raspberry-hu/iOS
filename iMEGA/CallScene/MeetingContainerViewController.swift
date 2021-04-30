
final class MeetingContainerViewController: UIViewController {
    
    private let viewModel: MeetingContainerViewModel
    
    init(viewModel: MeetingContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        viewModel.dispatch(.onViewReady)
    }
}
