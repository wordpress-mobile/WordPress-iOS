import UIKit
import WordPressAuthenticator

class RegisterDomainSuggestionsViewController: NUXViewController, DomainSuggestionsButtonViewPresenter {

    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!
    private var domain: String?
    private var siteName: String?
    private var domainsTableViewController: RegisterDomainSuggestionsTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showButtonView(show: false, withAnimation: false)
    }

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: NSLocalizedString("Choose domain",
                                       comment: "Register domain - Title for the Choose domain button of Suggested domains screen")
        )
        return buttonViewController
    }()

    static func instance(siteName: String? = nil) -> RegisterDomainSuggestionsViewController {
        let storyboard = UIStoryboard(name: "RegisterDomain", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "RegisterDomainSuggestionsViewController") as! RegisterDomainSuggestionsViewController
        controller.siteName = siteName
        return controller
    }

    private func configure() {
        title = NSLocalizedString("Register domain",
                                  comment: "Register domain - Title for the Suggested domains screen")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        let backButton = UIBarButtonItem()
        backButton.title = NSLocalizedString("Back", comment: "Back button title.")
        navigationItem.backBarButtonItem = backButton
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? RegisterDomainSuggestionsTableViewController {
            vc.delegate = self
            vc.siteName = siteName
            domainsTableViewController = vc
        }
    }
}

// MARK: - DomainSuggestionsTableViewControllerDelegate

extension RegisterDomainSuggestionsViewController: DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: String) {
        self.domain = domain
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension RegisterDomainSuggestionsViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        guard let domain = domain else {
            return
        }
        let controller = RegisterDomainDetailsViewController()
        controller.viewModel = RegisterDomainDetailsViewModel(domain: domain)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
