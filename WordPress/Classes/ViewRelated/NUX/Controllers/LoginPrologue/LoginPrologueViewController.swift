import SwiftUI
import UIKit
import WordPressData
import WordPressShared
import WordPressUI

/// The app-owned login prologue: brand content on top, sign-in buttons at the bottom.
/// Replaces the WordPressAuthenticator library's prologue screen, so the layout and
/// analytics replicate the library's unified prologue.
final class LoginPrologueViewController: UIViewController {

    private let brandViewController: UIViewController = {
        if AppConfiguration.isWordPress {
            return SplashPrologueViewController()
        }
        return JetpackPrologueViewController(nibName: "JetpackPrologueViewController", bundle: .keystone)
    }()

    private var buttonStackLeadingConstraint: NSLayoutConstraint?
    private var buttonStackTrailingConstraint: NSLayoutConstraint?

    /// The unified-login `prologue` step is tracked once per instance, unlike
    /// `.loginPrologueViewed` which is tracked on every appearance.
    private var prologueStepTracked = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let brandContainerView = makeBrandContainerView()
        let buttonAreaView = makeButtonAreaView()
        view.addSubview(brandContainerView)
        view.addSubview(buttonAreaView)

        NSLayoutConstraint.activate([
            brandContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            brandContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            brandContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            brandContainerView.bottomAnchor.constraint(equalTo: buttonAreaView.topAnchor),
            buttonAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonAreaView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Guard against background launches triggering view appearance callbacks.
        guard UIApplication.shared.applicationState != .background else {
            return
        }

        WPAnalytics.track(.loginPrologueViewed)

        if !prologueStepTracked {
            Analytics.trackStep()
            prologueStepTracked = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateButtonStackMargins()
    }

    // MARK: - View setup

    private func makeBrandContainerView() -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        addChild(brandViewController)
        brandViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(brandViewController.view)
        containerView.pinSubviewToAllEdges(brandViewController.view)
        brandViewController.didMove(toParent: self)

        return containerView
    }

    private func makeButtonAreaView() -> UIView {
        let areaView = UIView()
        areaView.translatesAutoresizingMaskIntoConstraints = false

        if AppConfiguration.isWordPress {
            areaView.backgroundColor = UIColor(light: .white, dark: .black)

            // The shadow occupies the 10pt strip directly above the button area,
            // overlapping the brand content's bottom edge.
            let shadowView = UIImageView(image: UIImage(named: "darkgrey-shadow"))
            shadowView.translatesAutoresizingMaskIntoConstraints = false
            areaView.addSubview(shadowView)
            NSLayoutConstraint.activate([
                shadowView.leadingAnchor.constraint(equalTo: areaView.leadingAnchor),
                shadowView.trailingAnchor.constraint(equalTo: areaView.trailingAnchor),
                shadowView.bottomAnchor.constraint(equalTo: areaView.topAnchor),
                shadowView.heightAnchor.constraint(equalToConstant: 10)
            ])
        } else {
            let backdropView = UIView()
            backdropView.backgroundColor = JetpackPrologueStyleGuide.gradientColor
            backdropView.translatesAutoresizingMaskIntoConstraints = false
            areaView.addSubview(backdropView)
            areaView.pinSubviewToAllEdges(backdropView)

            let blurEffectView = UIVisualEffectView(effect: JetpackPrologueStyleGuide.prologueButtonsBlurEffect)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            areaView.addSubview(blurEffectView)
            areaView.pinSubviewToAllEdges(blurEffectView)
        }

        let stackView = UIStackView(arrangedSubviews: [makeContinueButton(), makeSiteAddressButton()])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        areaView.addSubview(stackView)

        let leadingConstraint = stackView.leadingAnchor.constraint(
            equalTo: areaView.safeAreaLayoutGuide.leadingAnchor,
            constant: 16
        )
        let trailingConstraint = areaView.safeAreaLayoutGuide.trailingAnchor.constraint(
            equalTo: stackView.trailingAnchor,
            constant: 16
        )
        buttonStackLeadingConstraint = leadingConstraint
        buttonStackTrailingConstraint = trailingConstraint
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            stackView.topAnchor.constraint(equalTo: areaView.topAnchor, constant: 16),
            areaView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16)
        ])

        return areaView
    }

    /// Widens the button margins on iPad, like the library prologue did.
    private func updateButtonStackMargins() {
        let margin: CGFloat
        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            let multiplier: CGFloat = view.bounds.width > view.bounds.height ? 0.25 : 0.1667
            margin = 16 + view.bounds.width * multiplier
        } else {
            margin = 16
        }
        buttonStackLeadingConstraint?.constant = margin
        buttonStackTrailingConstraint?.constant = margin
    }

    // MARK: - Buttons

    private func makeContinueButton() -> UIButton {
        let button = makeButton(
            title: Strings.continueWithDotCom,
            isPrimary: true,
            accessibilityIdentifier: "Prologue Continue Button"
        )
        button.addTarget(self, action: #selector(continueWithWordPressDotComTapped), for: .touchUpInside)
        return button
    }

    private func makeSiteAddressButton() -> UIButton {
        let button = makeButton(
            title: Strings.enterSiteAddress,
            isPrimary: false,
            accessibilityIdentifier: "Prologue Self Hosted Button"
        )
        button.addTarget(self, action: #selector(siteAddressTapped), for: .touchUpInside)
        return button
    }

    private func makeButton(title: String, isPrimary: Bool, accessibilityIdentifier: String) -> UIButton {
        let button = UIButton(
            configuration: Self.buttonConfiguration(title: title, isPrimary: isPrimary, highlighted: false)
        )
        button.configurationUpdateHandler = { button in
            button.configuration = Self.buttonConfiguration(
                title: title,
                isPrimary: isPrimary,
                highlighted: button.isHighlighted
            )
        }
        button.accessibilityIdentifier = accessibilityIdentifier
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        // The buttons must never absorb leftover vertical space; the brand container
        // above them (whose SwiftUI content hugs at default priority) takes it instead.
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }

    private static func buttonConfiguration(title: String, isPrimary: Bool, highlighted: Bool) -> UIButton.Configuration
    { // swiftlint:disable:this opening_brace
        var configuration: UIButton.Configuration
        if AppConfiguration.isWordPress {
            configuration =
                isPrimary
                ? SplashPrologueStyleGuide.primaryButtonConfiguration(highlighted: highlighted)
                : SplashPrologueStyleGuide.secondaryButtonConfiguration(highlighted: highlighted)
        } else {
            configuration =
                isPrimary
                ? JetpackPrologueStyleGuide.primaryButtonConfiguration(highlighted: highlighted)
                : JetpackPrologueStyleGuide.secondaryButtonConfiguration(highlighted: highlighted)
        }
        configuration.title = title
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = WPStyleGuide.mediumWeightFont(forStyle: .body)
            return attributes
        }
        return configuration
    }

    // MARK: - Actions

    @objc private func continueWithWordPressDotComTapped() {
        Analytics.track(click: "continue_with_wordpress_com")

        Task { @MainActor in
            let accountID = await WordPressDotComAuthenticator().signIn(from: self, context: .default)
            if accountID != nil {
                guard let navigationController = self.navigationController else {
                    return wpAssertionFailure("the login prologue must be embedded in a navigation controller")
                }
                WordPressAppDelegate.shared?.presentDefaultAccountPrimarySite(from: navigationController)
            }
        }
    }

    @objc private func siteAddressTapped() {
        Analytics.track(click: "login_with_site_address")

        let loginCompleted: (TaggedManagedObjectID<Blog>) -> Void = { [weak self] blogID in
            guard let self else {
                return
            }
            self.dismiss(animated: true)
            guard let blog = try? ContextManager.shared.mainContext.existingObject(with: blogID) else {
                return wpAssertionFailure("the app has just signed into this blog")
            }
            guard let navigationController = self.navigationController else {
                return wpAssertionFailure("the login prologue must be embedded in a navigation controller")
            }
            WordPressAppDelegate.shared?.present(selfHostedSite: blog, from: navigationController)
        }
        let presentDotComLogin: () -> Void = { [weak self] in
            self?.continueWithWordPressDotComTapped()
        }
        let view = NavigationStack {
            LoginWithUrlView(presenter: self, loginCompleted: loginCompleted, presentDotComLogin: presentDotComLogin)
        }
        let hostVC = UIHostingController(rootView: view)
        hostVC.modalPresentationStyle = .formSheet
        present(hostVC, animated: true)
    }
}

// MARK: - Navigation controller

/// Hosts the login prologue. Locks iPhone to portrait like the library's
/// LoginNavigationController did; the navigation bar is managed by the prologue itself.
final class LoginPrologueNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return topViewController?.supportedInterfaceOrientations ?? .all
        }
        return .portrait
    }
}

// MARK: - Analytics

/// Replicates the unified-login events the WordPressAuthenticator library's
/// `AuthenticatorAnalyticsTracker` fired from its prologue screen.
private enum Analytics {
    static let properties = [
        "flow": "prologue",
        "source": "default",
        "step": "prologue"
    ]

    static func trackStep() {
        WPAnalytics.track(AnalyticsEvent(name: "unified_login_step", properties: properties))
    }

    static func track(click: String) {
        var properties = properties
        properties["click"] = click
        WPAnalytics.track(AnalyticsEvent(name: "unified_login_interaction", properties: properties))
    }
}

// MARK: - Strings

private enum Strings {
    // These two strings intentionally keep the legacy localization keys used by the
    // previous prologue, so the existing translations carry over.
    static let continueWithDotCom = NSLocalizedString(
        "Continue With WordPress.com",
        comment: "Button title. Takes the user to the login with WordPress.com flow."
    )
    static let enterSiteAddress = NSLocalizedString(
        "Enter your existing site address",
        comment: "Button title. Takes the user to the login by site address flow."
    )
}
