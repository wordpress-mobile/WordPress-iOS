import UIKit
import WordPressUI
import WordPressShared

final class MagicLinkRequestedViewController: LoginViewController {

    // MARK: Properties

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var cannotFindEmailLabel: UILabel!
    @IBOutlet private weak var buttonContainerView: UIView!
    @IBOutlet private weak var loginWithPasswordButton: UIButton!

    private let email: String
    private let loginWithPassword: () -> Void

    private lazy var buttonViewController: NUXButtonViewController = .instance()

    init(email: String, loginWithPassword: @escaping () -> Void) {
        self.email = email
        self.loginWithPassword = loginWithPassword
        super.init(nibName: "MagicLinkRequestedViewController", bundle: WordPressAuthenticator.bundle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var sourceTag: WordPressSupportSourceTag {
        .wpComLoginMagicLinkAutoRequested
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        setupButtons()
        setupTitleLabel()
        setupSubtitleLabel()
        setupEmailLabel()
        setupCannotFindEmailLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracker.set(flow: .loginWithMagicLink)

        if isBeingPresentedInAnyWay {
            tracker.track(step: .magicLinkAutoRequested)
        } else {
            tracker.set(step: .magicLinkAutoRequested)
        }
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            return super.styleBackground()
        }
        view.backgroundColor = unifiedBackgroundColor
    }

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }
}

private extension MagicLinkRequestedViewController {
    func setupButtons() {
        setupContinueMailButton()
        setupLoginWithPasswordButton()
    }

    /// Configures the primary button using the shared NUXButton style without a Storyboard.
    func setupContinueMailButton() {
        buttonViewController.setupTopButton(title: WordPressAuthenticator.shared.displayStrings.openMailButtonTitle, isPrimary: true, onTap: { [weak self] in
            guard let self else { return }
            guard let topButton = self.buttonViewController.topButton else {
                return
            }
            self.openMail(sender: topButton)
        })
        buttonViewController.move(to: self, into: buttonContainerView)
    }

    /// Unfortunately, the plain text button style is not available in `NUXButton` as it currently supports primary or secondary.
    /// The plain text button is configured manually here.
    func setupLoginWithPasswordButton() {
        loginWithPasswordButton.setTitle(Localization.loginWithPasswordAction, for: .normal)
        loginWithPasswordButton.applyLinkButtonStyle()
        loginWithPasswordButton.on(.touchUpInside) { [weak self] _ in
            self?.loginWithPassword()
        }
    }

    func setupTitleLabel() {
        titleLabel.text = Localization.title
        titleLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .title3)
        titleLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor
        titleLabel.numberOfLines = 0
    }

    func setupSubtitleLabel() {
        subtitleLabel.text = Localization.subtitle
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body)
        subtitleLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor
        subtitleLabel.numberOfLines = 0
    }

    func setupEmailLabel() {
        emailLabel.text = email
        emailLabel.numberOfLines = 0
        emailLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
        emailLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor
    }

    func setupCannotFindEmailLabel() {
        cannotFindEmailLabel.text = Localization.cannotFindMailLoginInstructions
        cannotFindEmailLabel.numberOfLines = 0
        cannotFindEmailLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        cannotFindEmailLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor
    }
}

private extension MagicLinkRequestedViewController {
    func openMail(sender: UIView) {
        tracker.track(click: .openEmailClient)
        tracker.track(step: .emailOpened)

        let linkMailPresenter = LinkMailPresenter(emailAddress: email)
        let appSelector = AppSelector(sourceView: sender)
        linkMailPresenter.presentEmailClients(on: self, appSelector: appSelector)
    }
}

private extension MagicLinkRequestedViewController {
    enum Localization {
        static let cannotFindMailLoginInstructions = NSLocalizedString("If you can’t find the email, please check your junk or spam email folder",
                                                                       comment: "The instructions text about not being able to find the magic link email.")
        static let title = NSLocalizedString("Check your email on this device!",
                                             comment: "The title text on the magic link requested screen.")
        static let subtitle = NSLocalizedString("We just sent a magic link to",
                                                comment: "The subtitle text on the magic link requested screen followed by the email address.")
        static let loginWithPasswordAction = NSLocalizedString("Use password to sign in",
                                                               comment: "The button title text for logging in with WP.com password instead of magic link.")
    }
}
