import UIKit
import WordPressAuthenticator

class RegisterDomainSuggestionsViewController: NUXViewController, DomainSuggestionsButtonViewPresenter {

    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!

    private var site: JetpackSiteRef!
    private var domainPurchasedCallback: ((String) -> Void)!

    private var domain: DomainSuggestion?
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
        buttonViewController.view.backgroundColor = .basicBackground
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: NSLocalizedString("Choose domain",
                                       comment: "Register domain - Title for the Choose domain button of Suggested domains screen")
        )
        return buttonViewController
    }()

    static func instance(site: JetpackSiteRef, domainPurchasedCallback: @escaping ((String) -> Void)) -> RegisterDomainSuggestionsViewController {
        let storyboard = UIStoryboard(name: "RegisterDomain", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "RegisterDomainSuggestionsViewController") as! RegisterDomainSuggestionsViewController
        controller.site = site
        controller.domainPurchasedCallback = domainPurchasedCallback
        controller.siteName = siteNameForSuggestions(for: site)

        return controller
    }

    private static func siteNameForSuggestions(for site: JetpackSiteRef) -> String? {
        if let siteTitle = BlogService.blog(with: site)?.settings?.name?.nonEmptyString() {
            return siteTitle
        }

        if let siteUrl = BlogService.blog(with: site)?.url {
            let components = URLComponents(string: siteUrl)
            if let firstComponent = components?.host?.split(separator: ".").first {
                return String(firstComponent)
            }
        }

        return nil
    }

    private func configure() {
        title = NSLocalizedString("Register domain",
                                  comment: "Register domain - Title for the Suggested domains screen")
        WPStyleGuide.configureColors(view: view, tableView: nil)
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

            if BlogService.blog(with: site)?.hasBloggerPlan == true {
                vc.domainSuggestionType = .whitelistedTopLevelDomains(["blog"])
            }

            domainsTableViewController = vc
        }
    }
}

// MARK: - DomainSuggestionsTableViewControllerDelegate

extension RegisterDomainSuggestionsViewController: DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: DomainSuggestion) {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionSelected)
        self.domain = domain
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionQueried)
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
        controller.viewModel = RegisterDomainDetailsViewModel(site: site, domain: domain, domainPurchasedCallback: domainPurchasedCallback)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
