import UIKit

class SiteCreationCreateSiteViewController: NUXViewController {

    // MARK: - Properties

    @IBOutlet weak var layingFoundationLabel: UILabel!
    @IBOutlet weak var retrievingInformationLabel: UILabel!
    @IBOutlet weak var configureContentLabel: UILabel!
    @IBOutlet weak var configureStyleLabel: UILabel!
    @IBOutlet weak var preparingFrontendLabel: UILabel!

    private var newSite: Blog?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        setLabelText()
        createSite()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        addWordPressLogoToNavController()
        // Remove help button.
        navigationItem.rightBarButtonItems = nil
        // Remove Back button. There's no going back now!
        navigationItem.hidesBackButton = true
    }

    private func setLabelText() {
        layingFoundationLabel.text = NSLocalizedString("Laying site foundation...", comment: "Text shown during the site creation process when it is on the first step.")
        retrievingInformationLabel.text = NSLocalizedString("Retrieving site information...", comment: "Text shown during the site creation process when it is on the second step.")
        configureContentLabel.text = NSLocalizedString("Configure site content...", comment: "Text shown during the site creation process when it is on the third step.")
        configureStyleLabel.text = NSLocalizedString("Configure site style...", comment: "Text shown during the site creation process when it is on the fourth step.")
        preparingFrontendLabel.text = NSLocalizedString("Preparing frontend...", comment: "Text shown during the site creation process when it is on the fifth step.")
    }

    // MARK: - Create Site

    private func createSite() {

        // Make sure we have all required info before proceeding.
        if let error = SiteCreationFields.validateFields() {
            DDLogError("Error while creating site: \(String(describing: error))")
            self.performSegue(withIdentifier: .showSiteCreationError, sender: self)
            return
        }

        // Blocks for Create Site process

        let statusBlock = { (status: SiteCreationStatus) in
            self.showStepLabelForStatus(status)
        }

        let successBlock = { (blog: Blog) in

            // Touch site so the app recognizes it as the last used.
            // Primarily so the 'write first post' action from the epilogue
            // defaults to the new site.
            if let siteUrl = blog.url {
                RecentSitesService().touch(site: siteUrl)
            }

            self.newSite = blog
            self.performSegue(withIdentifier: .showSiteCreationEpilogue, sender: self)
        }

        let failureBlock = { (error: Error?) in
            DDLogError("Error while creating site: \(String(describing: error))")
            self.performSegue(withIdentifier: .showSiteCreationError, sender: self)
        }

        // Start the site creation process
        let siteCreationFields = SiteCreationFields.sharedInstance
        let service = SiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.createSite(siteURL: siteCreationFields.domain,
                           siteTitle: siteCreationFields.title,
                           siteTagline: siteCreationFields.tagline,
                           siteTheme: siteCreationFields.theme,
                           status: statusBlock,
                           success: successBlock,
                           failure: failureBlock)
    }

    private func showStepLabelForStatus(_ status: SiteCreationStatus) {

        let labelToUpdate: UILabel = {
            switch status {
            case .validating:
                return layingFoundationLabel
            case .creatingSite:
                return retrievingInformationLabel
            case .settingTagline:
                return configureContentLabel
            case .settingTheme:
                return configureStyleLabel
            case .syncing:
                return preparingFrontendLabel
            }
        }()

        labelToUpdate.font = WPStyleGuide.fontForTextStyle(.headline)
        labelToUpdate.textColor = WPStyleGuide.darkGrey()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationEpilogueViewController {
            vc.siteToShow = newSite
        }

        if let vc = segue.destination as? NoResultsViewController {

            vc.configure(title: NSLocalizedString("Something went wrong...", comment: "Primary message on site creation error page."),
                         buttonTitle: NSLocalizedString("Try again", comment: "Button text on site creation error page."),
                         subTitle: NSLocalizedString("A parliament of owls distracted our servers with their superior oratory skills.", comment: "Secondary message on site creation error page."))
            vc.delegate = self
        }
    }
}

// MARK: - NoResultsViewControllerDelegate

extension SiteCreationCreateSiteViewController: NoResultsViewControllerDelegate {

    func actionButtonPressed() {
        print("SGH - create site > error > actionButtonPressed")
        navigationController?.dismiss(animated: true, completion: nil)

    }

}
