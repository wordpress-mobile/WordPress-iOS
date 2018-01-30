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
            // TODO: show whoops view
            showAlertWithMessage("Error: \(String(describing: error))")
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
            // TODO: show whoops view
            self.showAlertWithMessage("Fail: '\(String(describing: error)).")
        }

        // Start the site creation process
        let siteCreationFields = SiteCreationFields.sharedInstance()
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

    private func showAlertWithMessage(_ alertMessage: String) {
        let message = "\(alertMessage)\nThis is a work in progress. To use the old flow, disable the siteCreation feature flag."
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)

        let goHome = UIAlertAction(
            title: "Go Home",
            style: .destructive,
            handler: { [unowned self] _ in
                self.navigationController?.dismiss(animated: true, completion: nil)
        })

        alertController.addAction(goHome)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationEpilogueViewController {
            vc.siteToShow = newSite
        }
    }
}
