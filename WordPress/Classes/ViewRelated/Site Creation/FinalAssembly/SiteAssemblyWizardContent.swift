
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

    /// The new `Blog`, if successfully created; `nil` otherwise.
    private var createdBlog: Blog?

    /// The content view serves as the root view of this view controller.
    private let contentView = SiteAssemblyContentView()

    /// We reuse a `NUXButtonViewController` from `WordPressAuthenticator`. Ideally this might be in `WordPressUI`.
    private let buttonViewController = NUXButtonViewController.instance()

    /// This view controller manages the interaction with error states that can arise during site assembly.
    private var errorStateViewController: ErrorStateViewController?

    /// Locally tracks the network connection status via `NetworkStatusDelegate`
    private var isNetworkActive = ReachabilityUtils.isInternetReachable()

    // MARK: SiteAssemblyWizardContent

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - creator: the in-flight creation instance
    ///   - service: the service to use for initiating site creation
    init(creator: SiteCreator, service: SiteAssemblyService) {
        self.siteCreator = creator
        self.service = service

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func loadView() {
        super.loadView()
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        installButtonViewController()
        WPAnalytics.track(.enhancedSiteCreationSuccessLoading)
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
        do {
            let creationRequest = try siteCreator.build()

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
                    WPAnalytics.track(.createdSite)
                }

                self.contentView.status = status
            }
        } catch {
            DDLogError("Unable to proceed in Site Creation flow due to an unexpected error")
            assertionFailure(error.localizedDescription)
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

        configuration.contactSupportActionHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.contactSupportTapped()
        }

        configuration.retryActionHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.retryTapped()
        }

        configuration.dismissalActionHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.dismissTapped()
        }

        let errorStateViewController = ErrorStateViewController(with: configuration)

        contentView.errorStateView = errorStateViewController.view

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
        supportVC.showFromTabBar()
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
        dismissTapped(viaDone: true) { [createdBlog, weak self] in
            guard let blog = createdBlog else {
                return
            }
            WPAnalytics.track(.enhancedSiteCreationSuccessPreviewOkButtonTapped)
            WPTabBarController.sharedInstance().switchMySitesTabToBlogDetails(for: blog)

            self?.showQuickStartAlert(for: blog)
        }
    }

    private func showQuickStartAlert(for blog: Blog) {
        guard !UserDefaults.standard.quickStartWasDismissedPermanently else {
            return
        }

        guard let tabBar = WPTabBarController.sharedInstance() else {
            return
        }

        let fancyAlert = FancyAlertViewController.makeQuickStartAlertController(blog: blog)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = tabBar
        tabBar.present(fancyAlert, animated: true)
    }
}
