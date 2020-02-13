import UIKit

extension NSNotification.Name {
    static let createSite = NSNotification.Name(rawValue: "PSICreateSite")
    static let addSelfHosted = NSNotification.Name(rawValue: "PSIAddSelfHosted")
}

private struct Constants {
    static let userDefaultsKeyFormat = "PostSignUpInterstitial.hasSeenBefore.%@"

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

    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .listBackground

        configureI18N()

        //Mark it as seen
        PostSignUpInterstitialViewController.markAsSeen()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - IBAction's
    @IBAction func createSite(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .createSite, object: nil)
        }
    }

    @IBAction func addSelfHosted(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .addSelfHosted, object: nil)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Private
    private func configureI18N() {
        welcomeLabel.text = Constants.welcomeTitleText
        subTitleLabel.text = Constants.subTitleText
        createSiteButton.setTitle(Constants.createSiteButtonTitleText, for: .normal)
        addSelfHostedButton.setTitle(Constants.addSelfHostedButtonTitleText, for: .normal)
        cancelButton.setTitle(Constants.cancelButtonTitleText, for: .normal)
    }
}

// MARK: - Display Logic and Helpers
extension PostSignUpInterstitialViewController {
    /// Determines whether or not the PSI should be displayed for the logged in user
    /// - Parameters:
    ///   - numberOfBlogs: The number of blogs the account has
    @objc class func shouldDisplay(numberOfBlogs: Int) -> Bool {
        if !AccountHelper.isLoggedIn || hasSeenBefore() {
            return false
        }

        return (numberOfBlogs == 0)
    }
}

private extension PostSignUpInterstitialViewController {
    /// Generates the user defaults key for the logged in user
    /// Returns nil if we can not get the default WP.com account
    class var userDefaultsKey: String? {
        get {
            guard
                let account = defaultWPComAccount(),
                let userId = account.userID
            else {
                return nil
            }

            return String.init(format: Constants.userDefaultsKeyFormat, userId)
        }
    }

    /// Determines whether the PSI has been displayed to the logged in user
    class func hasSeenBefore() -> Bool {
        guard let key = userDefaultsKey else {
            return false
        }

        return UserDefaults.standard.bool(forKey: key)
    }

    /// Marks the PSI as seen for the logged in user
    class func markAsSeen() {
        guard let key = userDefaultsKey else {
            return
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    /// Grabs the default WordPress.com account
    class func defaultWPComAccount() -> WPAccount? {
        let acctServ = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        return acctServ.defaultWordPressComAccount()
    }
}
