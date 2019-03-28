import Foundation
import UIKit
import WordPressShared
import WordPressAuthenticator


/// A view controller that presents a Jetpack login form.
///
class JetpackLoginViewController: UIViewController {

    // MARK: - Constants

    fileprivate let jetpackInstallRelativePath = "plugin-install.php?tab=plugin-information&plugin=jetpack"
    var blog: Blog

    // MARK: - Properties

    // Defaulting to stats because since that one is written in ObcC we don't have access to the enum there.
    var promptType: JetpackLoginPromptType = .stats

    typealias CompletionBlock = () -> Void
    /// This completion handler closure is executed when the authentication process handled
    /// by this VC is completed.
    ///
    @objc open var completionBlock: CompletionBlock?

    @IBOutlet fileprivate weak var jetpackImage: UIImageView!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var signinButton: WPNUXMainButton!
    @IBOutlet fileprivate weak var installJetpackButton: WPNUXMainButton!
    @IBOutlet private var tacButton: UIButton!
    @IBOutlet private var faqButton: UIButton!

    /// Returns true if the blog has the proper version of Jetpack installed,
    /// otherwise false
    ///
    fileprivate var hasJetpack: Bool {
        guard let jetpack = blog.jetpack else {
            return false
        }
        return (jetpack.isConnected && jetpack.isUpdatedToRequiredVersion)
    }

    // MARK: - Initializers

    /// Required initializer for JetpackLoginViewController
    ///
    /// - Parameter blog: The current blog
    ///
    @objc init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Jetpack Login View Controller must be initialized by code")
    }

    // MARK: - LifeCycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
        setupControls()
    }

    // MARK: - Configuration

    /// One time setup of the form textfields and buttons
    ///
    fileprivate func setupControls() {
        jetpackImage.image = promptType.image

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = WPStyleGuide.darkGrey()

        tacButton.titleLabel?.numberOfLines = 0

        faqButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
        faqButton.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)

        updateMessageAndButton()
    }

    fileprivate func observeLoginNotifications(_ observe: Bool) {
        if observe {
            // Observe `.handleLoginSyncedSites` instead of `WPSigninDidFinishNotification`
            // `WPSigninDidFinishNotification` will not be dispatched for Jetpack logins.
            // Switch back to `WPSigninDidFinishNotification` when the WPTabViewController
            // no longer destroys and recreates its view hierarchy in response to that
            // notification.
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleFinishedJetpackLogin), name: .wordpressLoginFinishedJetpackLogin, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleLoginCancelled), name: .wordpressLoginCancelled, object: nil)
            return
        }

        NotificationCenter.default.removeObserver(self, name: .wordpressLoginFinishedJetpackLogin, object: nil)
        NotificationCenter.default.removeObserver(self, name: .wordpressLoginCancelled, object: nil)
    }

    @objc fileprivate func handleLoginCancelled() {
        observeLoginNotifications(false)
    }

    @objc fileprivate func handleFinishedJetpackLogin() {
        observeLoginNotifications(false)
        completionBlock?()
    }


    // MARK: - UI Helpers

    func updateMessageAndButton() {
        guard let jetPack = blog.jetpack else {
            return
        }

        var message: String

        if jetPack.isConnected {
            message = jetPack.isUpdatedToRequiredVersion ? Constants.Jetpack.isUpdated : Constants.Jetpack.updateRequired
        } else {
            message = promptType.message
        }
        descriptionLabel.text = message
        descriptionLabel.sizeToFit()

        let title = Feature.enabled(.jetpackRemoteInstallation) ? Constants.Buttons.jetpackInstallTitle : Constants.Buttons.jetpackSetupTitle
        installJetpackButton.setTitle(title, for: .normal)
        installJetpackButton.isHidden = hasJetpack

        signinButton.setTitle(Constants.Buttons.loginTitle, for: .normal)
        signinButton.isHidden = !hasJetpack

        // If .jetpackRemoteInstallation is not enabled
        // I want to skip the buttons configuration and hide those buttons
        guard Feature.enabled(.jetpackRemoteInstallation) else {
            tacButton.isHidden = true
            faqButton.isHidden = tacButton.isHidden
            return
        }

        let paragraph = NSMutableParagraphStyle(minLineHeight: WPStyleGuide.fontSizeForTextStyle(.footnote),
                                                lineBreakMode: .byWordWrapping,
                                                alignment: .center)
        let attributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.footnote),
                                                         .foregroundColor: WPStyleGuide.darkGrey(),
                                                         .paragraphStyle: paragraph]
        let attributedTitle = NSMutableAttributedString(string: Constants.Buttons.termsAndConditionsTitle,
                                                        attributes: attributes)
        attributedTitle.applyStylesToMatchesWithPattern(Constants.Buttons.termsAndConditions,
                                                        styles: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        tacButton.setAttributedTitle(attributedTitle, for: .normal)
        tacButton.isHidden = installJetpackButton.isHidden

        faqButton.setTitle(Constants.Buttons.faqTitle, for: .normal)
        faqButton.isHidden = tacButton.isHidden
    }

    // MARK: - Private Helpers

    fileprivate func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    // MARK: - Browser

    fileprivate func openInstallJetpackURL() {
        trackStat(.selectedInstallJetpack)
        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true)
    }

    fileprivate func signIn() {
        observeLoginNotifications(true)
        WordPressAuthenticator.showLoginForJustWPCom(from: self, xmlrpc: blog.xmlrpc, username: blog.username, connectedEmail: blog.jetpack?.connectedEmail)
    }

    fileprivate func trackStat(_ stat: WPAnalyticsStat) {
        var properties = [String: String]()
        switch promptType {
        case .stats:
            properties["source"] = "stats"
        case .notifications:
            properties["source"] = "notifications"
        }
        WPAnalytics.track(stat, withProperties: properties)
    }

    private func openWebView(for webviewType: JetpackWebviewType) {
        guard let url = webviewType.url else {
            return
        }

        let webviewViewController = WebViewControllerFactory.controller(url: url)
        let navigationViewController = UINavigationController(rootViewController: webviewViewController)
        present(navigationViewController, animated: true, completion: nil)
    }

    // MARK: - Actions

    @IBAction func didTouchSignInButton(_ sender: Any) {
        signIn()
    }

    @IBAction func didTouchInstallJetpackButton(_ sender: Any) {
        guard Feature.enabled(.jetpackRemoteInstallation) else {
            openInstallJetpackURL()
            return
        }
        // Open new Jetpack remote installation
    }

    @IBAction func didTouchTacButton(_ sender: Any) {
        openWebView(for: .tac)
    }

    @IBAction func didTouchFaqButton(_ sender: Any) {
        openWebView(for: .faq)
    }
}

extension JetpackLoginViewController: JetpackConnectionWebDelegate {
    func jetpackConnectionCompleted() {
        trackStat(.installJetpackCompleted)
        dismiss(animated: true, completion: completionBlock)
    }

    func jetpackConnectionCanceled() {
        trackStat(.installJetpackCanceled)
        dismiss(animated: true, completion: completionBlock)
    }
}

public enum JetpackLoginPromptType {
    case stats
    case notifications

    var image: UIImage? {
        switch self {
        case .stats:
            return UIImage(named: "wp-illustration-stats")
        case .notifications:
            return UIImage(named: "wp-illustration-notifications")
        }
    }

    var message: String {
        switch (self, Feature.enabled(.jetpackRemoteInstallation)) {
        case (.stats, true):
            return NSLocalizedString("To use stats on your site, you'll need to install the Jetpack plugin.",
                                        comment: "Message asking the user if they want to set up Jetpack from stats")
        case (.stats, false):
            return NSLocalizedString("To use Stats on your site, you'll need to install the Jetpack plugin.\n Would you like to set up Jetpack?",
                                     comment: "Message asking the user if they want to set up Jetpack from stats")
        case (.notifications, true):
            return NSLocalizedString("To get helpful notifications on your phone from your WordPress site, you'll need to install the Jetpack plugin.",
                                        comment: "Message asking the user if they want to set up Jetpack from notifications")
        case (.notifications, false):
            return NSLocalizedString("To get helpful notifications on your phone from your WordPress site, you'll need to install the Jetpack plugin. Would you like to set up Jetpack?",
                                     comment: "Message asking the user if they want to set up Jetpack from notifications")
        }
    }
}

private enum JetpackWebviewType {
    case tac
    case faq

    var url: URL? {
        switch self {
        case .tac:
            return URL(string: "https://en.wordpress.com/tos/")
        case .faq:
            return URL(string: "https://wordpress.org/plugins/jetpack/#faq")
        }
    }
}

private enum Constants {
    enum Buttons {
        static let termsAndConditions = NSLocalizedString("Terms and Conditions", comment: "The underlined title sentence")
        static let termsAndConditionsTitle = String.localizedStringWithFormat(NSLocalizedString("By setting up Jetpack you agree to our\n%@",
                                                                                                comment: "Title of the button which opens the Jetpack terms and conditions page."), termsAndConditions)
        static let faqTitle = NSLocalizedString("Jetpack FAQ", comment: "Title of the button which opens the Jetpack FAQ page.")
        static let jetpackInstallTitle = NSLocalizedString("Install Jetpack", comment: "Title of a button for Jetpack Installation.")
        static let jetpackSetupTitle = NSLocalizedString("Set up Jetpack", comment: "Title of a button for Jetpack Set up.")
        static let loginTitle = NSLocalizedString("Log in", comment: "Title of a button for signing in.")
    }

    enum Jetpack {
        static let isUpdated = NSLocalizedString("Looks like you have Jetpack set up on your site. Congrats! " +
            "Log in with your WordPress.com credentials to enable " +
            "Stats and Notifications.",
                                                      comment: "Message asking the user to sign into Jetpack with WordPress.com credentials")
        static let updateRequired = String.localizedStringWithFormat(NSLocalizedString("Jetpack %@ or later is required. " +
            "Do you want to update Jetpack?",
                                                                                              comment: "Message stating the minimum required " +
                                                                                                "version for Jetpack and asks the user " +
            "if they want to upgrade"), JetpackState.minimumVersionRequired)
    }
}
