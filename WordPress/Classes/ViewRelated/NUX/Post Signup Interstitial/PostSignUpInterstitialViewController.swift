import UIKit

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

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .listBackground

        configureI18N()

        let coordinator = PostSignUpInterstitialCoordinator()
        coordinator.markAsSeen()

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
        onDismiss?()
        navigationController?.dismiss(animated: false) {
            NotificationCenter.default.post(name: .createSite, object: nil)
        }

        WPAnalytics.track(.welcomeNoSitesInterstitialButtonTapped, withProperties: ["button": "create_new_site"])
    }

    @IBAction func addSelfHosted(_ sender: Any) {
        onDismiss?()
        navigationController?.dismiss(animated: false) {
            NotificationCenter.default.post(name: .addSelfHosted, object: nil)
        }

        WPAnalytics.track(.welcomeNoSitesInterstitialButtonTapped, withProperties: ["button": "add_self_hosted_site"])
    }

    @IBAction func cancel(_ sender: Any) {
        onDismiss?()

        WPTabBarController.sharedInstance().showReaderTab()
        navigationController?.dismiss(animated: true, completion: nil)

        WPAnalytics.track(.welcomeNoSitesInterstitialDismissed)
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
        let numberOfBlogs = self.numberOfBlogs()

        let coordinator = PostSignUpInterstitialCoordinator()
        return coordinator.shouldDisplay(numberOfBlogs: numberOfBlogs)
    }

    private class func numberOfBlogs() -> Int {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        let blogCount = blogService.blogCountForAllAccounts()

        return blogCount
    }
}
