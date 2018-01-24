import UIKit

class SiteCreationCreateSiteViewController: NUXViewController {

    // MARK: - Properties

    // Used to store Site Creation user options.
    var siteOptions: [String: Any]?

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

        // Make sure we have the bare minimum before proceeding.
        guard let siteOptions = siteOptions,
            let siteURL = siteOptions["domain"] as? String,
            let siteTitle = siteOptions["title"] as? String else {
                DDLogError("Error while creating site: siteURL and/or siteTitle missing.")
                // TODO: show whoops view
                self.showAlertWithMessage("Fail: URL and/or Title missing.")
                return
        }

        // Blocks for Create Site process

        let statusBlock = { (status: SiteCreationStatus) in
            self.showStepLabelForStatus(status)
        }


        let successBlock = { (blog: Blog) in
            self.newSite = blog
            self.performSegue(withIdentifier: .showSiteCreationEpilogue, sender: self)
        }

        let failureBlock = { (error: Error?) in
            DDLogError("Error while creating site: \(String(describing: error))")
            // TODO: show whoops view
            self.showAlertWithMessage("Fail: '\(String(describing: error)).")
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
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationEpilogueViewController {
            vc.siteToShow = newSite
        }
    }
}
