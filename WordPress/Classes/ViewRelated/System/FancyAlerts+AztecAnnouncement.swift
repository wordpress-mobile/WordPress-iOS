import UIKit
import Gridicons
import WordPressShared

let AztecAnnouncementWhatsNewURL = URL(string: "https://make.wordpress.org/mobile/whats-new-in-beta-ios-editor/")


extension FancyAlertViewController {
    private enum Constants {
        static let successAnimationTransform: CGAffineTransform = {
            let translate =
                CGAffineTransform(translationX: 0, y: 60)
            let scale = CGAffineTransform(scaleX: 0.01, y: 0.01)
            let rotate = CGAffineTransform(rotationAngle: 0.261799)

            return scale.concatenating(rotate).concatenating(translate)
        }()
        static let successAnimationDuration: TimeInterval = 0.8
        static let successAnimationDampingRaio: CGFloat = 0.6
        static let confettiViewInset: CGSize = CGSize(width: -20.0, height: -40.0)
        static let confettiDuration: TimeInterval = 2.0
    }

    static func aztecAnnouncementController() -> FancyAlertViewController {
        if EditorSettings().nativeEditorEnabled {
            return existingTesterAztecAnnouncementController()
        } else {
            return newTesterAztecAnnouncementController()
        }
    }

    // Shown to users of the app who don't have Aztec enabled
    private static func newTesterAztecAnnouncementController() -> FancyAlertViewController {
        struct Strings {
            static let titleText = NSLocalizedString("Try the New Editor", comment: "Title of alert prompting users to try the new Aztec editor")
            static let bodyText = NSLocalizedString("The WordPress app now includes a beautiful new editor. Try it out by creating a new post!", comment: "Body text of alert prompting users to try the new Aztec editor")
            static let tryIt = NSLocalizedString("Try It", comment: "Title of the primary button on alert prompting users to try the new Aztec editor")
            static let notNow = NSLocalizedString("Not Now", comment: "Title of the cancel button on alert prompting users to try the new Aztec editor")
            static let whatsNew = NSLocalizedString("What's new?", comment: "Title of more info button on alert prompting users to try the new Aztec editor")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let enableEditor = {
            let settings = EditorSettings(database: UserDefaults.standard)
            settings.visualEditorEnabled = true
            settings.nativeEditorEnabled = true

            WPAnalytics.track(.editorToggledOn)
        }

        let addConfetti: (FancyAlertButtonHandler) = { controller in
            guard let imageView = controller.headerImageView, let imageViewHolder = imageView.superview else { return }

            let confettiView = ConfettiView.aztecAnnouncementConfettiView()
            confettiView.frame = imageViewHolder.bounds.insetBy(dx: Constants.confettiViewInset.width,
                                                                dy: Constants.confettiViewInset.height)
            imageView.superview?.addSubview(confettiView)

            confettiView.start(duration: Constants.confettiDuration)
        }

        let defaultButton = Button(Strings.tryIt, { controller in
            WPAppAnalytics.track(.editorAztecPromoPositive)

            enableEditor()

            controller.setViewConfiguration(aztecAnnouncementSuccessConfig,
                                            animated: true,
                                            alongside: { controller in
                                                UIView.performWithoutAnimation {
                                                    controller.headerImageView.transform = Constants.successAnimationTransform
                                                }

                                                let animator = UIViewPropertyAnimator(duration: Constants.successAnimationDuration,
                                                                       dampingRatio: Constants.successAnimationDampingRaio,
                                                                       animations: {
                                                    controller.headerImageView.transform = CGAffineTransform.identity
                                                })

                                                animator.addCompletion({ _ in
                                                    addConfetti(controller)
                                                })

                                                animator.startAnimation()
            })
        })

        let cancelButton = Button(Strings.notNow, { controller in
            WPAppAnalytics.track(.editorAztecPromoNegative)
            controller.dismiss(animated: true, completion: nil)
        })

        let moreInfoButton = Button(Strings.whatsNew, { controller in
            WPAppAnalytics.track(.editorAztecPromoLink)
            WPWebViewController.presentWhatsNewWebView(from: controller)
        })

        let image = UIImage(named: "wp-illustration-hand-write")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: defaultButton,
                                                     cancelButton: cancelButton,
                                                     moreInfoButton: moreInfoButton,
                                                     titleAccessoryButton: nil,
                                                     dismissAction: nil)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    // Shown to users of the app who already have Aztec enabled
    static func existingTesterAztecAnnouncementController() -> FancyAlertViewController {
        struct Strings {
            static let titleText = NSLocalizedString("New Editor!", comment: "Title of alert prompting users to try the new Aztec editor")
            static let bodyText = NSLocalizedString("The WordPress app's beautiful new editor is now in public beta. It looks like you already have it enabled, so you're all set!", comment: "Body text of alert informing existing testers that the new Aztec editor is now public")
            static let whatsNew = NSLocalizedString("What's new?", comment: "Title of more info button on alert prompting users to try the new Aztec editor")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let moreInfoButton = Button(Strings.whatsNew, { controller in
            WPAppAnalytics.track(.editorAztecPromoLink)
            WPWebViewController.presentWhatsNewWebView(from: controller)
        })

        let image = UIImage(named: "wp-illustration-hand-write")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     dividerPosition: .bottom,
                                                     defaultButton: nil,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreInfoButton, titleAccessoryButton: nil, dismissAction: nil)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    private static let aztecAnnouncementSuccessConfig: FancyAlertViewController.Config = {
        struct Strings {
            static let titleText = NSLocalizedString("New Editor Enabled!", comment: "Title of alert informing users that the new Aztec editor has been enabled")
            static let bodyText = NSLocalizedString("Thanks for trying it out! You can switch editor modes at any time in", comment: "Body text of alert informing users that the new Aztec editor has been enabled")
            static let appSettings = NSLocalizedString("Me > App Settings", comment: "Text for button telling user where to find the App Settings section of the app")
        }

        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let moreInfoButton = Button(Strings.appSettings, { controller in
            controller.presentingViewController?.dismiss(animated: true, completion: {
                WPTabBarController.sharedInstance().switchMeTabToAppSettings()
            })
        })

        let image = UIImage(named: "wp-illustration-thank-you")

        return FancyAlertViewController.Config(titleText: Strings.titleText,
                                               bodyText: Strings.bodyText,
                                               headerImage: image,
                                               dividerPosition: .bottom,
                                               defaultButton: nil, cancelButton: nil, moreInfoButton: moreInfoButton, titleAccessoryButton: nil,
                                               dismissAction: {
                                                WPTabBarController.sharedInstance().showPostTab(animated: true, toMedia: false)
        })
    }()
}

private extension ConfettiView {
    static func aztecAnnouncementConfettiView() -> ConfettiView {
        let colors: [UIColor] = [ UIColor(hexString: "FCC320"),
                                  UIColor(hexString: "FDD665"),
                                  UIColor(hexString: "0083C2"),
                                  UIColor(hexString: "C0F4FF"),
                                  UIColor(hexString: "78DFBF"),
                                  UIColor(hexString: "C976CE"),
                                  UIColor(hexString: "DAA0DD"),
                                  UIColor(hexString: "C7D7E3") ]
        return ConfettiView(colors: colors)
    }
}

// MARK: - User Defaults

extension UserDefaults {
    private enum Keys: String {
        case aztecAnnouncement = "AztecBetaAnnouncementWasDisplayed"
    }

    var aztecAnnouncementWasDisplayed: Bool {
        get {
            return bool(forKey: Keys.aztecAnnouncement.rawValue)
        }
        set {
            set(newValue, forKey: Keys.aztecAnnouncement.rawValue)
        }
    }
}

// MARK: - What's New Web View

extension WPWebViewController {
    static func presentWhatsNewWebView(from viewController: UIViewController) {
        // Replace the web view's options button with our own bug reporting button
        let bugButton = UIBarButtonItem(image: Gridicon.iconOfType(.bug), style: .plain, target: self, action: #selector(bugButtonTapped))
        bugButton.accessibilityLabel = NSLocalizedString("Report a bug", comment: "Button allowing the user to report a bug with the beta Aztec editor")

        let webViewController = WPWebViewController()
        webViewController.url = AztecAnnouncementWhatsNewURL

        if HelpshiftUtils.isHelpshiftEnabled() {
            webViewController.optionsButton = bugButton
        }

        let navigationController = UINavigationController(rootViewController: webViewController)

        viewController.present(navigationController, animated: true, completion: nil)
    }

    @objc static private func bugButtonTapped() {
        // Find the topmost view controller that we can present from
        guard let delegate = UIApplication.shared.delegate,
            let window = delegate.window,
            let viewController = window?.topmostPresentedViewController else { return }

        guard HelpshiftUtils.isHelpshiftEnabled() else { return }

        let presenter = HelpshiftPresenter()
        presenter.sourceTag = SupportSourceTag.aztecFeedback
        presenter.presentHelpshiftConversationWindowFromViewController(viewController,
                                                                       refreshUserDetails: true,
                                                                       completion:nil)
    }
}

private let contactURL = "https://support.wordpress.com/contact/"
