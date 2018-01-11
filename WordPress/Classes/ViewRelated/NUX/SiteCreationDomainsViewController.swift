import UIKit

class SiteCreationDomainsViewController: NUXAbstractViewController {

    // MARK: - Properties

    open var siteName: String?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComCreateSiteDomain
        }
    }

    private var domainsTableViewController: SiteCreationDomainsTableViewController?
    private var buttonViewController: SiteCreationButtonViewController?
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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? SiteCreationDomainsTableViewController {
            domainsTableViewController = vc
            domainsTableViewController?.delegate = self
            domainsTableViewController?.siteName = siteName
        }

        if let vc = segue.destination as? SiteCreationButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
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
    }
}

// MARK: - SiteCreationButtonViewControllerDelegate

extension SiteCreationDomainsViewController: SiteCreationButtonViewControllerDelegate {
    func continueButtonPressed() {
        let message = "'\(selectedDomain ?? "")' selected.\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        self.present(alertController, animated: true, completion: nil)
    }
}
