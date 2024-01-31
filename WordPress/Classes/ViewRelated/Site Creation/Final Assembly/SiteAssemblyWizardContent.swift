
import UIKit

import WordPressAuthenticator

// MARK: - SiteAssemblyWizardContent

/// This view controller manages the final step in the enhanced site creation sequence - invoking the service &
/// apprising the user of the outcome.
final class SiteAssemblyWizardContent: UIViewController {

    // MARK: Properties

    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator

    /// The service with which the final assembly interacts to coordinate site creation.
    private let service: SiteAssemblyService

    /// Displays the domain and plan checkout web view.
    private lazy var siteCreationPurchasingController = SiteCreationPurchasingWebFlowController(viewController: self, origin: .siteCreation)

    /// The new `Blog`, if successfully created; `nil` otherwise.
    private var createdBlog: Blog?

    /// The content view serves as the root view of this view controller.
    private let contentView: SiteAssemblyContentView

    /// We reuse a `NUXButtonViewController` from `WordPressAuthenticator`. Ideally this might be in `WordPressUI`.
    private let buttonViewController = NUXButtonViewController.instance()

    /// This view controller manages the interaction with error states that can arise during site assembly.
    private var errorStateViewController: ErrorStateViewController?

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    /// UseDefaults helper for quick start settings
    private let quickStartSettings: QuickStartSettings

    /// Closure to be executed upon dismissal
    private let onDismiss: ((Blog, Bool) -> Void)?

    // MARK: SiteAssemblyWizardContent

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - creator: the in-flight creation instance
    ///   - service: the service to use for initiating site creation
    ///   - quickStartSettings: the UserDefaults helper for quick start settings
    ///   - onDismiss: the closure to be executed upon dismissal
    init(creator: SiteCreator,
         service: SiteAssemblyService,
         quickStartSettings: QuickStartSettings = QuickStartSettings(),
         onDismiss: ((Blog, Bool) -> Void)? = nil) {
        self.siteCreator = creator
        self.service = service
        self.quickStartSettings = quickStartSettings
        self.onDismiss = onDismiss
        self.contentView = SiteAssemblyContentView(siteCreator: siteCreator)

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        installButtonViewController()
        SiteCreationAnalyticsHelper.trackSiteCreationSuccessLoading(siteCreator.design)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
        setNeedsStatusBarAppearanceUpdate()

        observeNetworkStatus()

        if service.currentStatus == .idle {
            attemptSiteCreation()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.contentView.adjustConstraints()
        })
    }

    // MARK: Private behavior

    private func attemptSiteCreation() {
        let creationRequest = siteCreator.build()
        let shouldPerformPurchasingStep = siteCreator.shouldShowCheckout
        service.createSite(creationRequest: creationRequest) { [weak self] status in
            guard let self = self else {
                return
            }

            if status == .failed {
                let errorType: ErrorStateViewType
                if self.isNetworkActive == false {
                    errorType = .networkUnreachable
                } else {
                    errorType = .siteLoading
                }
                self.installErrorStateViewController(with: errorType)
            } else if status == .succeeded {
                let blog = self.service.createdBlog
                // Default all new blogs to use Gutenberg
                if let createdBlog = blog {
                    let gutenbergSettings = GutenbergSettings()
                    gutenbergSettings.softSetGutenbergEnabled(true, for: createdBlog, source: .onSiteCreation)
                    gutenbergSettings.postSettingsToRemote(for: createdBlog)
                }

                self.contentView.siteURLString = blog?.url as String?
                self.contentView.siteName = blog?.displayURL as String?
                self.createdBlog = blog

                // This stat is part of a funnel that provides critical information.  Before
                // making ANY modification to this stat please refer to: p4qSXL-35X-p2
                SiteCreationAnalyticsHelper.trackSiteCreationSuccess(self.siteCreator.design)
            }
            if status == .succeeded,
               shouldPerformPurchasingStep,
               let domain = self.siteCreator.address,
               let planId = self.siteCreator.planId,
               let blog = self.createdBlog {
                self.attemptPurchasing(domain: domain, planId: planId, site: blog)
            } else {
                self.contentView.status = status
            }
        }
    }

    /// The site must be created before attempting plan and/or domain purchasing.
    private func attemptPurchasing(domain: DomainSuggestion, planId: Int, site: Blog) {
        self.siteCreationPurchasingController.purchase(domain: domain, planId: planId, site: site) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let domain):
                self.contentView.siteName = domain
                self.contentView.isFreeDomain = false
                self.contentView.status = .succeeded
            case .failure(let error):
                self.contentView.isFreeDomain = true
                switch error {
                case .unsupportedRedirect, .internal, .invalidInput, .other:
                    self.installDomainCheckoutErrorStateViewController(domain: domain, planId: planId, site: site)
                    self.contentView.status = .failed
                case .canceled:
                    self.contentView.status = .succeeded
                }
            }
        }
    }

    private func installButtonViewController() {
        buttonViewController.delegate = self

        let primaryButtonText = NSLocalizedString("Done",
                                                  comment: "Tapping a button with this label allows the user to exit the Site Creation flow")
        buttonViewController.setButtonTitles(primary: primaryButtonText)

        contentView.buttonContainerView = buttonViewController.view

        buttonViewController.willMove(toParent: self)
        addChild(buttonViewController)
        buttonViewController.didMove(toParent: self)
    }

    private func installErrorStateViewController(with type: ErrorStateViewType) {
        var configuration = ErrorStateViewConfiguration.configuration(type: type)

        configuration.retryActionHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.retryTapped()
        }

        self.installErrorStateViewController(with: configuration)
    }

    private func installDomainCheckoutErrorStateViewController(domain: DomainSuggestion, planId: Int, site: Blog) {
        var configuration = ErrorStateViewConfiguration.configuration(type: .domainCheckoutFailed)

        configuration.retryActionHandler = { [weak self] in
            guard let self else {
                return
            }
            self.contentView.status = .inProgress
            self.attemptPurchasing(domain: domain, planId: planId, site: site)
        }

        self.installErrorStateViewController(with: configuration)
    }

    private func installErrorStateViewController(with configuration: ErrorStateViewConfiguration) {
        var configuration = configuration

        if configuration.contactSupportActionHandler == nil {
            configuration.contactSupportActionHandler = { [weak self] in
                guard let self = self else {
                    return
                }
                self.contactSupportTapped()
            }
        }

        if configuration.dismissalActionHandler == nil {
            configuration.dismissalActionHandler = { [weak self] in
                guard let self else {
                    return
                }
                self.dismissTapped()
            }
        }

        // Remove previous error state view controller
        if let errorStateViewController {
            errorStateViewController.willMove(toParent: nil)
            errorStateViewController.view?.removeFromSuperview()
            errorStateViewController.removeFromParent()
            errorStateViewController.didMove(toParent: nil)
        }

        // Install new error state view controller
        let errorStateViewController = ErrorStateViewController(with: configuration)

        self.contentView.errorStateView = errorStateViewController.view

        errorStateViewController.willMove(toParent: self)
        addChild(errorStateViewController)
        errorStateViewController.didMove(toParent: self)

        self.errorStateViewController = errorStateViewController
    }
}

// MARK: ErrorStateViewController support

private extension SiteAssemblyWizardContent {
    func contactSupportTapped() {
        // TODO : capture analytics event via #10335
        let supportVC = SupportTableViewController()
        supportVC.show(from: self)
    }

    func dismissTapped(viaDone: Bool = false, completion: (() -> Void)? = nil) {
        // TODO : using viaDone, capture analytics event via #10335
        navigationController?.dismiss(animated: true, completion: completion)
    }

    func retryTapped(viaDone: Bool = false) {
        // TODO : using viaDone, capture analytics event via #10335
        attemptSiteCreation()
    }
}

// MARK: - NetworkStatusDelegate

extension SiteAssemblyWizardContent: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        isNetworkActive = active
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SiteAssemblyWizardContent: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        SiteCreationAnalyticsHelper.trackSiteCreationSuccessPreviewOkButtonTapped()

        guard let blog = createdBlog, let navigationController = navigationController else {
            return
        }

        if let onDismiss = self.onDismiss {
            let quickstartPrompt = QuickStartPromptViewController(blog: blog)
            quickstartPrompt.onDismiss = onDismiss
            navigationController.pushViewController(quickstartPrompt, animated: true)
            return
        }

        RootViewCoordinator.shared.isSiteCreationActive = false
        RootViewCoordinator.shared.reloadUIIfNeeded(blog: blog)

        dismissTapped(viaDone: true) { [blog, weak self] in
            RootViewCoordinator.sharedPresenter.showBlogDetails(for: blog)

            guard let self = self, AppConfiguration.isJetpack else {
                return
            }

            let completedSteps: [QuickStartTour] = self.siteCreator.hasSiteTitle ? [QuickStartSiteTitleTour(blog: blog)] : []
            self.showQuickStartPrompt(for: blog, completedSteps: completedSteps)
        }
    }

    private func showQuickStartPrompt(for blog: Blog, completedSteps: [QuickStartTour] = []) {
        guard !quickStartSettings.promptWasDismissed(for: blog) else {
            return
        }

        // Disable the prompt for WordPress when the blog has no domains.
        guard AppConfiguration.isJetpack || isDashboardEnabled(for: blog) else {
            return
        }

        let rootViewController = RootViewCoordinator.sharedPresenter.rootViewController
        let quickstartPrompt = QuickStartPromptViewController(blog: blog)
        quickstartPrompt.onDismiss = { blog, showQuickStart in
            if showQuickStart {
                QuickStartTourGuide.shared.setupWithDelay(for: blog, type: .newSite, withCompletedSteps: completedSteps)
            }
        }
        rootViewController.present(quickstartPrompt, animated: true)
    }

    private func isDashboardEnabled(for blog: Blog) -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && blog.isAccessibleThroughWPCom()
    }
}
