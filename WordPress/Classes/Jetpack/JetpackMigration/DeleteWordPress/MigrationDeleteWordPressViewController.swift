import UIKit
import WordPressUI

final class MigrationDeleteWordPressViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: MigrationDeleteWordPressViewModel

    private let tracker: MigrationAnalyticsTracker

    // MARK: - Init

    init(viewModel: MigrationDeleteWordPressViewModel, tracker: MigrationAnalyticsTracker = .init()) {
        self.viewModel = viewModel
        self.tracker = tracker
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let actions = MigrationDeleteWordPressViewModel.Actions()
        self.init(viewModel: MigrationDeleteWordPressViewModel(actions: actions))
        actions.primary = { [weak self] in
            self?.primaryButtonTapped()
        }
        actions.secondary = { [weak self] in
            self?.secondaryButtonTapped()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        let migrationView = MigrationStepView(
            headerView: MigrationHeaderView(configuration: viewModel.header),
            actionsView: MigrationActionsView(configuration: viewModel.actions),
            centerView: MigrationCenterView.deleteWordPress(with: viewModel.content)
        )
        migrationView.additionalContentInset.top = 0
        self.view = migrationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupDismissButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tracker.track(.pleaseDeleteWordPressScreenShown)
    }

    // MARK: - Setup

    private func setupDismissButton() {
        let closeButton = UIButton.makeCloseButton()
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        let item = UIBarButtonItem(customView: closeButton)
        self.navigationItem.rightBarButtonItem = item
    }

    // MARK: - User Interaction

    @objc private func closeButtonTapped() {
        self.tracker.track(.pleaseDeleteWordPressScreenCloseTapped)
        self.dismiss(animated: true)
    }

    private func primaryButtonTapped() {
        self.tracker.track(.pleaseDeleteWordPressScreenGotItTapped)
        self.dismiss(animated: true)
    }

    private func secondaryButtonTapped() {
        self.tracker.track(.pleaseDeleteWordPressScreenHelpTapped)
        let destination = SupportTableViewController()
        self.present(UINavigationController(rootViewController: destination), animated: true)
    }
}

private extension UIButton {

    private static var closeButtonImage: UIImage {
        let fontForSystemImage = UIFont.systemFont(ofSize: Metrics.closeButtonRadius)
        let configuration = UIImage.SymbolConfiguration(font: fontForSystemImage)

        // fallback to the gridicon if for any reason the system image fails to render
        return UIImage(systemName: Constants.closeButtonSystemName, withConfiguration: configuration) ??
        UIImage.gridicon(.crossCircle, size: CGSize(width: Metrics.closeButtonRadius, height: Metrics.closeButtonRadius))
    }

    static func makeCloseButton() -> UIButton {
        let closeButton = CircularImageButton()

        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tintColor = Colors.closeButtonTintColor
        closeButton.setImageBackgroundColor(UIColor(light: .black, dark: .white))

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])

        return closeButton
    }

    private enum Constants {
        static let closeButtonSystemName = "xmark.circle.fill"
    }

    private enum Metrics {
        static let closeButtonRadius: CGFloat = 30
    }

    private enum Colors {
        static let closeButtonTintColor = UIColor(
            light: UIAppColor.gray(.shade5),
            dark: UIAppColor.jetpackGreen(.shade90)
        )
    }
}
