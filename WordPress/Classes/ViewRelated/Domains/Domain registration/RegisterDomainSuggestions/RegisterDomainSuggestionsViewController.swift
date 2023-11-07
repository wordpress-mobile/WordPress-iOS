import SwiftUI
import UIKit
import WebKit
import WordPressAuthenticator
import WordPressFlux

enum DomainSelectionType {
    case registerWithPaidPlan
    case purchaseWithPaidPlan
    case purchaseSeparately
    case purchaseFromDomainManagement
}

class RegisterDomainSuggestionsViewController: UIViewController {

    @IBOutlet weak var buttonContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewHeightConstraint: NSLayoutConstraint!

    private var constraintsInitialized = false

    private var coordinator: RegisterDomainCoordinator?
    private var siteName: String?
    private var domainsTableViewController: DomainSuggestionsTableViewController?
    private var domainSelectionType: DomainSelectionType = .registerWithPaidPlan
    private var includeSupportButton: Bool = true
    private var navBarTitle: String = TextContent.title

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        hideButton()
    }

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.view.backgroundColor = .basicBackground
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: TextContent.primaryButtonTitle
        )
        return buttonViewController
    }()

    static func instance(coordinator: RegisterDomainCoordinator,
                         domainSelectionType: DomainSelectionType = .registerWithPaidPlan,
                         includeSupportButton: Bool = true,
                         title: String = TextContent.title) -> RegisterDomainSuggestionsViewController {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: Constants.viewControllerIdentifier) as! RegisterDomainSuggestionsViewController
        controller.coordinator = coordinator
        controller.domainSelectionType = domainSelectionType
        controller.includeSupportButton = includeSupportButton
        controller.siteName = siteNameForSuggestions(for: coordinator.site)
        controller.navBarTitle = title

        return controller
    }

    private static func siteNameForSuggestions(for site: Blog?) -> String? {
        guard let site else {
            return nil
        }

        if let siteTitle = site.settings?.name?.nonEmptyString() {
            return siteTitle
        }

        if let siteUrl = site.url {
            let components = URLComponents(string: siteUrl)
            if let firstComponent = components?.host?.split(separator: ".").first {
                return String(firstComponent)
            }
        }

        return nil
    }

    private func configure() {
        title = navBarTitle
        WPStyleGuide.configureColors(view: view, tableView: nil)

        /// If this is the first view controller in the navigation controller - show the cancel button
        if navigationController?.children.count == 1 {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                               target: self,
                                               action: #selector(handleCancelButtonTapped))
            navigationItem.leftBarButtonItem = cancelButton
        }

        guard includeSupportButton else {
            return
        }

        let supportButton = UIBarButtonItem(title: TextContent.supportButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(handleSupportButtonTapped))
        navigationItem.rightBarButtonItem = supportButton
    }

    // MARK: - Bottom Hideable Button

    /// Shows the domain picking button
    ///
    private func showButton() {
        buttonContainerBottomConstraint.constant = 0
    }

    /// Shows the domain picking button
    ///
    /// - Parameters:
    ///     - animated: whether the transition is animated.
    ///
    private func showButton(animated: Bool) {
        guard animated else {
            showButton()
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { [weak self] in
            guard let self = self else {
                return
            }

            self.showButton()

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func hideButton() {
        buttonViewContainer.layoutIfNeeded()
        buttonContainerBottomConstraint.constant = buttonViewContainer.frame.height
    }

    /// Hides the domain picking button
    ///
    /// - Parameters:
    ///     - animated: whether the transition is animated.
    ///
    func hideButton(animated: Bool) {
        guard animated else {
            hideButton()
            return
        }

        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { [weak self] in
            guard let self = self else {
                return
            }

            self.hideButton()

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? DomainSuggestionsTableViewController {
            vc.delegate = self
            vc.siteName = siteName
            vc.blog = coordinator?.site
            vc.domainSelectionType = domainSelectionType
            vc.primaryDomainAddress = coordinator?.site?.primaryDomainAddress

            if coordinator?.site?.hasBloggerPlan == true {
                vc.domainSuggestionType = .allowlistedTopLevelDomains(["blog"])
            }

            domainsTableViewController = vc
        }
    }

    // MARK: - Nav Bar Button Handling

    @objc private func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @objc private func handleSupportButtonTapped(sender: UIBarButtonItem) {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }

}

// MARK: - DomainSuggestionsTableViewControllerDelegate

extension RegisterDomainSuggestionsViewController: DomainSuggestionsTableViewControllerDelegate {
    func domainSelected(_ domain: FullyQuotedDomainSuggestion) {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionSelected)
        coordinator?.domain = domain
        showButton(animated: true)
    }

    func newSearchStarted() {
        WPAnalytics.track(.automatedTransferCustomDomainSuggestionQueried)
        hideButton(animated: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension RegisterDomainSuggestionsViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        guard let coordinator else {
            return
        }
        if let site = coordinator.site {
            WPAnalytics.track(.domainsSearchSelectDomainTapped, properties: WPAnalytics.domainsProperties(for: site), blog: site)
        } else {
            WPAnalytics.track(.domainsSearchSelectDomainTapped)
        }

        let onFailure: () -> () = { [weak self] in
            self?.displayActionableNotice(title: TextContent.errorTitle, actionTitle: TextContent.errorDismiss)
            self?.setPrimaryButtonLoading(false, afterDelay: 0.25)
        }

        switch domainSelectionType {
        case .registerWithPaidPlan:
            pushRegisterDomainDetailsViewController()
        case .purchaseSeparately:
            setPrimaryButtonLoading(true)
            coordinator.createCart(
                onSuccess: { [weak self] in
                    guard let self else { return }
                    self.coordinator?.presentWebViewForCurrentSite(on: self)
                    self.setPrimaryButtonLoading(false, afterDelay: 0.25)
                },
                onFailure: onFailure
            )
        case .purchaseWithPaidPlan:
            setPrimaryButtonLoading(true)
            coordinator.createCart(
                onSuccess: { [weak self] in
                    guard let self = self,
                          let domain = self.coordinator?.domain,
                          let blog = coordinator.site else {
                        return
                    }

                    self.coordinator?.domainAddedToCartCallback?(self, domain.domainName, blog)
                    self.setPrimaryButtonLoading(false, afterDelay: 0.25)
                },
                onFailure: onFailure
            )
        case .purchaseFromDomainManagement:
            pushPurchaseDomainChoiceScreen()
        }
    }

    private func setPrimaryButtonLoading(_ isLoading: Bool, afterDelay delay: Double = 0.0) {
        // We're dispatching here so that we can wait until after the webview has been
        // fully presented before we switch the button back to its default state.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.buttonViewController.setBottomButtonState(isLoading: isLoading,
                                                           isEnabled: !isLoading)
        }
    }

    private func pushRegisterDomainDetailsViewController() {
        guard let siteID = coordinator?.site?.dotComID?.intValue else {
            DDLogError("Cannot register domains for sites without a dotComID")
            return
        }

        guard let domain = coordinator?.domain else {
            return
        }

        let controller = RegisterDomainDetailsViewController()
        controller.viewModel = RegisterDomainDetailsViewModel(siteID: siteID, domain: domain) { [weak self] name in
            guard let self = self else {
                return
            }

            self.coordinator?.domainPurchasedCallback?(self, name)
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func pushPurchaseDomainChoiceScreen() {
        let view = DomainPurchaseChoicesView { [weak self] in
            guard let self else { return }
            self.coordinator?.handleNoSiteChoice(on: self)
        } chooseSiteAction: { [weak self] in
            guard let self else { return }
            self.coordinator?.handleExistingSiteChoice(on: self)
        }
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = TextContent.domainChoiceTitle
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
}

// MARK: - Constants
extension RegisterDomainSuggestionsViewController {

    enum TextContent {

        static let title = NSLocalizedString("Search domains",
                                             comment: "Search domain - Title for the Suggested domains screen")
        static let primaryButtonTitle = NSLocalizedString("Select domain",
                                                          comment: "Register domain - Title for the Choose domain button of Suggested domains screen")
        static let supportButtonTitle = NSLocalizedString("Help", comment: "Help button")

        static let errorTitle = NSLocalizedString("domains.failure.title",
                                                  value: "Sorry, the domain you are trying to add cannot be bought on the Jetpack app at this time.",
                                                  comment: "Content show when the domain selection action fails.")
        static let errorDismiss = NSLocalizedString("domains.failure.dismiss",
                                                    value: "Dismiss",
                                                    comment: "Action shown in a bottom notice to dismiss it.")
        static let domainChoiceTitle = NSLocalizedString("domains.purchase.choice.title",
                                                     value: "Purchase Domain",
                                                     comment: "Title for the screen where the user can choose how to use the domain they're end up purchasing.")
    }

    enum Constants {
        // storyboard identifiers
        static let storyboardIdentifier = "RegisterDomain"
        static let viewControllerIdentifier = "RegisterDomainSuggestionsViewController"
    }
}
