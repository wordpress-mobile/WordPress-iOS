import Foundation
import UIKit
import WordPressShared

/// A view controller that presents a Jetpack login form
///
class JetpackLoginViewController: UIViewController {

    // MARK: - Constants

    fileprivate let jetpackInstallRelativePath = "plugin-install.php?tab=plugin-information&plugin=jetpack"
    fileprivate let jetpackMoreInformationURL = "https://apps.wordpress.com/support/#faq-ios-15"
    fileprivate let blog: Blog

    // MARK: - Properties

    typealias CompletionBlock = () -> Void
    /// This completion handler closure is executed when the authentication process handled
    /// by this VC is completed.
    ///
    @objc open var completionBlock: CompletionBlock?

    @IBOutlet fileprivate weak var jetpackImage: UIImageView!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var signinButton: WPNUXMainButton!
    @IBOutlet fileprivate weak var installJetpackButton: WPNUXMainButton!
    @IBOutlet fileprivate weak var moreInformationButton: UIButton!

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
        descriptionLabel.font = WPNUXUtility.descriptionTextFont()
        descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()
        updateMessage()

        setupMoreInformationButtonText()
        moreInformationButton.isHidden = hasJetpack

        var title = NSLocalizedString("Set up Jetpack", comment: "Title of a button for Jetpack Installation. The text " +
                "should be uppercase.").localizedUppercase
        installJetpackButton.setTitle(title, for: .normal)
        installJetpackButton.isHidden = hasJetpack

        title = NSLocalizedString("Log In", comment: "Title of a button for signing in. " +
            "The text should be uppercase.").localizedUppercase
        signinButton.setTitle(title, for: .normal)
        signinButton.isHidden = !hasJetpack
    }

    /// Configures the button text for requesting more information about jetpack.
    ///
    fileprivate func setupMoreInformationButtonText() {
        let string = NSLocalizedString("More information",
                                       comment: "Text used for a button to request more information.")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ .font: UIFont.systemFont(ofSize: 14),
                                                                   .foregroundColor: WPStyleGuide.allTAllShadeGrey(),
                                                                   .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                                                                   .paragraphStyle: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        moreInformationButton.setAttributedTitle(attributedCode, for: UIControlState())
        moreInformationButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }

    fileprivate func observeLoginNotifications(_ observe: Bool) {
        if observe {
            // Observe `.handleLoginSyncedSites` instead of `WPSigninDidFinishNotification`
            // `WPSigninDidFinishNotification` will not be dispatched for Jetpack logins.
            // Switch back to `WPSigninDidFinishNotification` when the WPTabViewController
            // no longer destroys and recreates its view hierarchy in response to that
            // notification.
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleFinishedJetpackLogin), name: .WPLoginFinishedJetpackLogin, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleLoginCancelled), name: .WPLoginCancelled, object: nil)
            return
        }

        NotificationCenter.default.removeObserver(self, name: .WPLoginFinishedJetpackLogin, object: nil)
        NotificationCenter.default.removeObserver(self, name: .WPLoginCancelled, object: nil)
    }

    @objc fileprivate func handleLoginCancelled() {
        observeLoginNotifications(false)
    }

    @objc fileprivate func handleFinishedJetpackLogin() {
        observeLoginNotifications(false)
        completionBlock?()
    }


    // MARK: - UI Helpers

    fileprivate func updateMessage() {
        guard let jetPack = blog.jetpack else {
            return
        }

        var message: String

        if jetPack.isConnected {
            if jetPack.isUpdatedToRequiredVersion {
                message = NSLocalizedString("Looks like you have Jetpack set up on your site. Congrats! \n" +
                                            "Log in with your WordPress.com credentials to enable " +
                                            "Stats and Notifications.",
                                            comment: "Message asking the user to sign into Jetpack with WordPress.com credentials")
            } else {
                message = String.localizedStringWithFormat(NSLocalizedString("Jetpack %@ or later is required " +
                                                                             "for stats. Do you want to update Jetpack?",
                                                                             comment: "Message stating the minimum required " +
                                                                             "version for Jetpack and asks the user " +
                                                                             "if they want to upgrade"), JetpackState.minimumVersionRequired)
            }
        } else {
            message = NSLocalizedString("Jetpack is required for stats. Do you want to set up Jetpack?",
                                        comment: "Message asking the user if they want to set up Jetpack")
        }
        descriptionLabel.text = message
        descriptionLabel.sizeToFit()
    }

    // MARK: - Private Helpers

    fileprivate func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    // MARK: - Browser

    fileprivate func openInstallJetpackURL() {
        WPAppAnalytics.track(.selectedInstallJetpack)
        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }

    fileprivate func openMoreInformationURL() {
        WPAppAnalytics.track(.selectedLearnMoreInConnectToJetpackScreen)
        displayWebView(url: jetpackMoreInformationURL)
    }

    fileprivate func displayWebView(url: String) {
        guard let url =  URL(string: url) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url)

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            navController.modalPresentationStyle = .pageSheet
            present(navController, animated: true, completion: nil)
        }
    }

    fileprivate func signIn() {
        observeLoginNotifications(true)
        SigninHelpers.showLoginForJustWPComFromPresenter(self, forJetpackBlog: blog)
    }

    // MARK: - Actions

    @IBAction func didTouchSignInButton(_ sender: Any) {
        signIn()
    }

    @IBAction func didTouchInstallJetpackButton(_ sender: Any) {
        openInstallJetpackURL()
    }

    @IBAction func didTouchMoreInformationButton(_ sender: Any) {
        openMoreInformationURL()
    }
}

extension JetpackLoginViewController: JetpackConnectionWebDelegate {
    func jetpackConnectionCompleted() {
        WPAppAnalytics.track(.installJetpackCompleted)
        dismiss(animated: true, completion: completionBlock)
    }

    func jetpackConnectionCanceled() {
        WPAppAnalytics.track(.installJetpackCanceled)
        dismiss(animated: true, completion: completionBlock)
    }
}
