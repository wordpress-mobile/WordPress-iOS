import UIKit
import WordPressAuthenticator

extension NSNotification.Name {
    static let createSite = NSNotification.Name(rawValue: "PSICreateSite")
    static let addSelfHosted = NSNotification.Name(rawValue: "PSIAddSelfHosted")
}

@objc extension NSNotification {
    public static let PSICreateSite = NSNotification.Name.createSite
    public static let PSIAddSelfHosted = NSNotification.Name.addSelfHosted
}

private struct Constants {
    // I18N Strings
    static let welcomeTitleText = NSLocalizedString(
        "Welcome to WordPress",
        comment: "Post Signup Interstitial Title Text"
    )

    static let subTitleText = NSLocalizedString(
        "Whatever you want to create or share, we'll help you do it right here.",
        comment: "Post Signup Interstitial Subtitle Text"
    )

    static let createSiteButtonTitleText = NSLocalizedString(
        "Create a new site",
        comment: "Title for a button that when tapped starts the site creation process"
    )

    static let addSelfHostedButtonTitleText = NSLocalizedString(
        "Add a self-hosted site",
        comment: "Title for a button that when tapped starts the add self-hosted site process"
    )

    static let cancelButtonTitleText = NSLocalizedString(
        "Not right now",
        comment: "Title for a button that when tapped cancels the site creation process"
    )
}

class PostSignUpInterstitialViewController: UIViewController {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var createSiteButton: UIButton!
    @IBOutlet weak var addSelfHostedButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    enum DismissAction {
        case none
        case createSite
        case addSelfHosted
    }

    /// Closure to be executed upon dismissal.
    ///
    var dismiss: ((_ action: DismissAction) -> Void)?

    /// Analytics tracker
    ///
    private let tracker = AuthenticatorAnalyticsTracker.shared

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .listBackground

        configureI18N()

        WPAnalytics.track(.welcomeNoSitesInterstitialShown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - IBAction's
    @IBAction func createSite(_ sender: Any) {
        tracker.track(click: .createNewSite, ifTrackingNotEnabled: {
            WPAnalytics.track(.welcomeNoSitesInterstitialButtonTapped, withProperties: ["button": "create_new_site"])
        })

        dismiss?(.createSite)

    }

    @IBAction func addSelfHosted(_ sender: Any) {
        tracker.track(click: .addSelfHostedSite, ifTrackingNotEnabled: {
            WPAnalytics.track(.welcomeNoSitesInterstitialButtonTapped, withProperties: ["button": "add_self_hosted_site"])
        })

        dismiss?(.addSelfHosted)
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss?(.none)

        WPTabBarController.sharedInstance().showReaderTab()

        tracker.track(click: .dismiss, ifTrackingNotEnabled: {
            WPAnalytics.track(.welcomeNoSitesInterstitialDismissed)
        })
    }

    // MARK: - Private
    private func configureI18N() {
        welcomeLabel.text = Constants.welcomeTitleText
        subTitleLabel.text = Constants.subTitleText
        createSiteButton.setTitle(Constants.createSiteButtonTitleText, for: .normal)
        addSelfHostedButton.setTitle(Constants.addSelfHostedButtonTitleText, for: .normal)
        cancelButton.setTitle(Constants.cancelButtonTitleText, for: .normal)
    }

    /// Determines whether or not the PSI should be displayed for the logged in user
    @objc class func shouldDisplay() -> Bool {
        guard AppConfiguration.allowSiteCreation else {
            return false
        }

        return self.numberOfBlogs() == 0
    }

    private class func numberOfBlogs() -> Int {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        let blogCount = blogService.blogCountForAllAccounts()

        return blogCount
    }
}
