import UIKit

class SiteCreationCreateSiteViewController: NUXAbstractViewController {

    // MARK: - Properties

    // Used to store Site Creation user options.
    var siteOptions: [String: Any]?

    @IBOutlet weak var layingFoundationLabel: UILabel!
    @IBOutlet weak var retrievingInformationLabel: UILabel!
    @IBOutlet weak var configureContentLabel: UILabel!
    @IBOutlet weak var configureStyleLabel: UILabel!
    @IBOutlet weak var preparingFrontendLabel: UILabel!

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

        // Make sure we have the bare minimum before proceeding.
        guard let siteOptions = siteOptions,
            let siteURL = siteOptions["domain"] as? String,
            let siteTitle = siteOptions["title"] as? String else {
                // TODO: show whoops view
                return
        }

        // Blocks for Create Site process

        let statusBlock = { (status: SiteCreationStatus) in
            self.showStepLabelForStatus(status)
        }

        let successBlock = {
            // TODO: show prologue
        }

        let failureBlock = { (error: Error?) in
            DDLogError("Error while creating site: \(String(describing: error))")
            // TODO: show whoops view
        }

        // Get optional values from dictionary
        let siteTagline = siteOptions["tagline"] as? String
        let siteTheme = siteOptions["theme"] as? Theme

        // Start the site creation process
        let service = SiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.createSite(siteURL: siteURL,
                           siteTitle: siteTitle,
                           siteTagline: siteTagline,
                           siteTheme: siteTheme,
                           status: statusBlock,
                           success: successBlock,
                           failure: failureBlock)
    }

    private func showStepLabelForStatus(_ status: SiteCreationStatus) {

        let labelToUpdate: UILabel = {
            switch status {
            case .validating:
                return self.layingFoundationLabel
            case .creatingSite:
                return self.retrievingInformationLabel
            case .settingTagline:
                return self.configureContentLabel
            case .settingTheme:
                return self.configureStyleLabel
            case .syncing:
                return self.preparingFrontendLabel
            }
        }()

        labelToUpdate.font = WPStyleGuide.fontForTextStyle(.headline)
        labelToUpdate.textColor = WPStyleGuide.darkGrey()
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
