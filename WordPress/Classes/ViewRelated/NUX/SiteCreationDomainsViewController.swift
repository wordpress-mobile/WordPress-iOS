import UIKit
import WordPressAuthenticator


class SiteCreationDomainsViewController: NUXViewController {

    // MARK: - Properties

    // Used to hide/show the Buttom View
    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerHeightConstraint: NSLayoutConstraint!

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComCreateSiteDomain
        }
    }

    private var domainsTableViewController: SiteCreationDomainsTableViewController?

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
        }, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationDomainsTableViewController {
            domainsTableViewController = vc
            domainsTableViewController?.delegate = self
            domainsTableViewController?.siteName = SiteCreationFields.sharedInstance.title
        }
    }
}

// MARK: - SiteCreationDomainsTableViewControllerDelegate

extension SiteCreationDomainsViewController: SiteCreationDomainsTableViewControllerDelegate {
    func domainSelected(_ domain: String) {
        SiteCreationFields.sharedInstance.domain = domain
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
