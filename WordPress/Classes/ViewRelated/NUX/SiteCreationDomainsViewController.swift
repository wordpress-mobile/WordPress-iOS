import UIKit

class SiteCreationDomainsViewController: NUXViewController {

    // MARK: - Properties

    // Used to hide/show the Buttom View
    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerHeightConstraint: NSLayoutConstraint!

    // Used to store Site Creation user options.
    var siteOptions: [String: Any]?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComCreateSiteDomain
        }
    }

    private var domainsTableViewController: SiteCreationDomainsTableViewController?
    private var buttonViewController: NUXButtonViewController?
    private var selectedDomain: String?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        _ = addHelpButtonToNavController()
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
            if let siteOptions = siteOptions,
                let siteName = siteOptions["title"] as? String {
                domainsTableViewController?.siteName = siteName
            }
        }

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            buttonViewController?.setButtonTitles(primary: NSLocalizedString("Create site", comment: "Button text for creating a new site in the Site Creation process."))
            showButtonView(show: false, withAnimation: false)
        }

        if let vc = segue.destination as? SiteCreationCreateSiteViewController {

            // TODO: replace siteOptions with SiteCreationFields class when created.
            guard var siteOptions = siteOptions else {
                return
            }

            siteOptions["domain"] = selectedDomain
            vc.siteOptions = siteOptions
        }
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - SiteCreationDomainsTableViewControllerDelegate

extension SiteCreationDomainsViewController: SiteCreationDomainsTableViewControllerDelegate {
    func domainSelected(_ domain: String) {
        selectedDomain = domain
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationDomainsViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        performSegue(withIdentifier: .showCreateSite, sender: self)
    }
}
