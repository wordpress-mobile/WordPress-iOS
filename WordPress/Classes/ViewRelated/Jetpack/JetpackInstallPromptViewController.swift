import UIKit

class JetpackInstallPromptViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var installButton: UIButton!
    @IBOutlet weak var noThanksButton: UIButton!

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
    }

    @IBAction func noThanksTapped(_ sender: Any) {
        dismiss?(.noThanks)
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let installJetpack = NSNotification.Name(rawValue: "JetpackInstall")
}
