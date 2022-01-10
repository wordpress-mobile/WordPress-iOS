import UIKit

class JetpackInstallPromptViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var installButton: FancyButton!
    @IBOutlet weak var noThanksButton: FancyButton!
    @IBOutlet weak var learnMoreButton: FancyButton!
    @IBOutlet weak var buttonsStackView: UIStackView!

    // MARK: - Properties

    private let blog: Blog

    enum DismissAction {
        case install
        case noThanks
    }

    /// Closure to be executed upon dismissal.
    ///
    var dismiss: ((_ action: DismissAction) -> Void)?

    // MARK: - Init

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: - Actions

    @IBAction func installTapped(_ sender: Any) {
        dismiss?(.install)
        dismiss(animated: true)
    }

    @IBAction func noThanksTapped(_ sender: Any) {
        dismiss?(.noThanks)
        dismiss(animated: true)
    }

    @IBAction func learnMoreButtonTapped(_ sender: Any) {
        guard let url = URL(string: "https://jetpack.com/features/") else {
            return
        }

        let controller = WebViewControllerFactory.controller(url: url, source: "jetpack_prompt")
        let navController = UINavigationController(rootViewController: controller)
        self.present(navController, animated: true)
    }
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let installJetpack = NSNotification.Name(rawValue: "JetpackInstall")
}
