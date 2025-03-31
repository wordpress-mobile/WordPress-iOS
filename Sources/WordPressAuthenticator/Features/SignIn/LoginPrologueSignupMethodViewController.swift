import SafariServices
import WordPressUI
import WordPressShared

class LoginPrologueSignupMethodViewController: NUXViewController {
    /// Buttons at bottom of screen
    private var buttonViewController: NUXButtonViewController?

    /// Gesture recognizer for taps on the dialog if no buttons are present
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer?

    open var emailTapped: (() -> Void)?
    open var googleTapped: (() -> Void)?
    open var appleTapped: (() -> Void)?

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    /// The big transparent (dismiss) button behind the buttons
    @IBOutlet private weak var dismissButton: UIButton!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtonVC()
        configureForAccessibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureButtonVC() {
        guard let buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Sign up with Email", comment: "Button title. Tapping begins our normal sign up process.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false, accessibilityIdentifier: "Sign up with Email Button") { [weak self] in

            self?.tracker.set(flow: .wpCom)

            defer {
                WordPressAuthenticator.track(.signupEmailButtonTapped)
            }
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }

        buttonViewController.setupButtomButtonFor(socialService: .google) { [weak self] in
            self?.handleGoogleButtonTapped()
        }

        let termsButton = WPStyleGuide.termsButton()
        termsButton.on(.touchUpInside) { [weak self] _ in
            defer {
                self?.tracker.track(click: .termsOfService, ifTrackingNotEnabled: {
                    WordPressAuthenticator.track(.signupTermsButtonTapped)
                })
            }

            let safariViewController = SFSafariViewController(url: WordPressAuthenticator.shared.configuration.wpcomTermsOfServiceURL)
            safariViewController.modalPresentationStyle = .pageSheet
            self?.present(safariViewController, animated: true, completion: nil)
        }
        buttonViewController.stackView?.insertArrangedSubview(termsButton, at: 0)

        if WordPressAuthenticator.shared.configuration.enableSignInWithApple {
            buttonViewController.setupTertiaryButtonFor(socialService: .apple) { [weak self] in
                self?.handleAppleButtonTapped()
            }
        }

        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.buttonViewBackgroundColor
    }

    @IBAction func dismissTapped() {
        trackCancellationAndThenDismiss()
    }

    @objc func handleAppleButtonTapped() {
        tracker.set(flow: .signupWithApple)
        tracker.track(click: .signupWithApple, ifTrackingNotEnabled: {
            WordPressAuthenticator.track(.signupSocialButtonTapped, properties: ["source": "apple"])
        })

        dismiss(animated: true)
        appleTapped?()
    }

    @objc func handleGoogleButtonTapped() {
        tracker.set(flow: .signupWithGoogle)
        tracker.track(click: .signupWithGoogle, ifTrackingNotEnabled: {
            WordPressAuthenticator.track(.signupSocialButtonTapped, properties: ["source": "google"])
        })

        dismiss(animated: true)
        googleTapped?()
    }

    private func trackCancellationAndThenDismiss() {
        WordPressAuthenticator.track(.signupCancelled)
        dismiss(animated: true)
    }

    // MARK: - Accessibility

    private func configureForAccessibility() {
        dismissButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Accessibility label for the transparent space above the signup dialog which acts as a button to dismiss the dialog.")

        // Ensure that the first button (in buttonViewController) is automatically selected by
        // VoiceOver instead of the dismiss button.
        if buttonViewController?.isViewLoaded == true, let buttonsView = buttonViewController?.view {
            view.accessibilityElements = [
                buttonsView,
                dismissButton as Any
            ]
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        trackCancellationAndThenDismiss()
        return true
    }
}
