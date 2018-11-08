import UIKit
import WordPressAuthenticator
import WordPressShared

class SiteCreationDomainsViewController: NUXViewController, DomainSuggestionsButtonViewPresenter {

    // MARK: - Properties

    // Used to hide/show the Buttom View
    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComCreateSiteDomain
        }
    }

    private var domainsTableViewController: SiteCreationDomainSuggestionsTableViewController?

    // MARK: - ButtonViewController

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(primary: ButtonTitles.primary)
        return buttonViewController
    }()


    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showButtonView(show: false, withAnimation: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WPAppAnalytics.track(.createSiteDomainViewed)
    }

    private func configureView() {
        setupHelpButtonIfNeeded()
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    private func showButtonView(show: Bool, withAnimation: Bool) {

        let duration = withAnimation ? WPAnimationDurationDefault : 0

        UIView.animate(withDuration: duration, animations: {
            if show {
                self.buttonContainerViewBottomConstraint.constant = 0
            }
            else {
                // Move the view down double the height to ensure it's off the screen.
                // i.e. to defy iPhone X bottom gap.
                self.buttonContainerViewBottomConstraint.constant +=
                    self.buttonContainerHeightConstraint.constant * 2
            }

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationDomainSuggestionsTableViewController {
            domainsTableViewController = vc
            domainsTableViewController?.delegate = self
            domainsTableViewController?.siteName = SiteCreationFields.sharedInstance.title
        }
    }
}

// MARK: - DomainSuggestionsTableViewControllerDelegate

extension SiteCreationDomainsViewController: DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: DomainSuggestion) {
        let domainName = domain.domainName.removingSuffix(".wordpress.com")

        SiteCreationFields.sharedInstance.domain = domainName
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationDomainsViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        performSegue(withIdentifier: Constants.createSiteSegueIdentifier, sender: self)
    }
}


// MARK: - Constants

private extension SiteCreationDomainsViewController {

    enum ButtonTitles {
        static let primary = NSLocalizedString("Create site", comment: "Button text for creating a new site in the Site Creation process.")
    }

    enum Constants {
        static let createSiteSegueIdentifier = "showCreateSite"
    }
}
