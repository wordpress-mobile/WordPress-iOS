import SwiftUI
import BuildSettingsKit
import WordPressKit
import WordPressShared
import DesignSystem

/// The Site Domains  screen, accessible from My Site
struct SiteDomainsView: View {

    @ObservedObject var blog: Blog
    @State var isShowingDomainSelectionWithType: DomainSelectionType?
    @StateObject var viewModel: SiteDomainsViewModel
    let context: PresentationContext

    final class PresentationContext {
        weak var viewController: UIViewController?
    }

    // Property observer
    private func showingDomainSelectionWithType(to value: DomainSelectionType?) {
        switch value {
        case .registerWithPaidPlan:
            WPAnalytics.track(.domainsDashboardAddDomainTapped, properties: WPAnalytics.domainsProperties(for: blog), blog: blog)
        case .purchaseSeparately:
            WPAnalytics.track(.domainsDashboardGetDomainTapped, properties: WPAnalytics.domainsProperties(for: blog), blog: blog)
        case .purchaseWithPaidPlan:
            WPAnalytics.track(.domainsDashboardGetPlanTapped, properties: WPAnalytics.domainsProperties(for: blog), blog: blog)
        case .none:
            break
        default:
            break
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)

            switch viewModel.state {
            case .normal(let sections):
                List {
                    makeDomainsSections(blog: blog, sections: sections)
                }
                .listRowSeparator(.hidden)
                //.listRowSpacing(.DS.Padding.double) Re-enable when we update to Xcode 15
            case .message(let messageViewModel):
                VStack {
                    HStack(alignment: .center) {
                        DomainsStateView(viewModel: messageViewModel)
                            .padding(.horizontal, .DS.Padding.double)
                    }
                }
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(item: $isShowingDomainSelectionWithType, content: { domainSelectionType in
            makeDomainSearch(for: blog, domainSelectionType: domainSelectionType, onDismiss: {
                isShowingDomainSelectionWithType = nil
                viewModel.refresh()
            })
            .ignoresSafeArea()
        })
    }

    // MARK: - Domains Section

    /// Builds the domains list section with the` add a domain` button at the bottom, for the given blog
    @ViewBuilder
    private func makeDomainsSections(blog: Blog, sections: [SiteDomainsViewModel.Section]) -> some View {
        ForEach(sections, id: \.id) { section in
            switch section.content {
            case .rows(let rows):
                makeDomainsListSection(blog: blog, section: section, rows: rows)
            case .addDomain:
                makeAddDomainSection(blog: blog)
            case .upgradePlan:
                makeGetFirstDomainSection(blog: blog)
            }
        }
    }

    private func makeDomainsListSection(blog: Blog, section: SiteDomainsViewModel.Section, rows: [SiteDomainsViewModel.Section.Row]) -> some View {
        Section {
            ForEach(rows) { row  in
                if let navigation = row.navigation {
                    Button(action: { showDetails(for: navigation) }) {
                        HStack(alignment: .center) {
                            AllDomainsListCardView(viewModel: row.viewModel, padding: 0)
                            Image(systemName: "chevron.forward")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                } else {
                    AllDomainsListCardView(viewModel: row.viewModel, padding: 0)
                }
            }
        } header: {
            if let title = section.title {
                Text(title)
            }
        } footer: {
            if let footer = section.footer {
                Text(footer)
            }
        }
    }

    private func showDetails(for navigation: SiteDomainsViewModel.Navigation) {
        wpAssert(context.viewController != nil)

        let viewController = DomainDetailsWebViewController(
            domain: navigation.domain,
            siteSlug: navigation.siteSlug,
            type: navigation.type,
            analyticsSource: navigation.analyticsSource
        ).makeLightNavigationController()
        context.viewController?.present(viewController, animated: true)
    }

    private func makeAddDomainSection(blog: Blog) -> some View {
        let destination: DomainSelectionType = blog.canRegisterDomainWithPaidPlan ? .registerWithPaidPlan : .purchaseSeparately

        return Section {
            Button {
                $isShowingDomainSelectionWithType.onChange(showingDomainSelectionWithType).wrappedValue = destination
            } label: {
                Text(TextContent.additionalDomainTitle(blog.canRegisterDomainWithPaidPlan))
                    .style(TextStyle.bodyMedium(.regular))
                    .foregroundColor(AppColor.primary)
            }
        }
    }

    // MARK: - First Domain Section

    /// Builds the Get New Domain section when no othert domains are present for the given blog
    private func makeGetFirstDomainSection(blog: Blog) -> some View {
        Section {
            SiteDomainsPresentationCard(
                title: TextContent.firstDomainTitle(blog.canRegisterDomainWithPaidPlan),
                description: TextContent.firstDomainDescription(blog.canRegisterDomainWithPaidPlan),
                destinations: makeGetFirstDomainSectionDestinations(blog: blog)
            )
        }
    }

    private func makeGetFirstDomainSectionDestinations(blog: Blog) -> [SiteDomainsPresentationCard.Destination] {
        let primaryDestination: DomainSelectionType = blog.canRegisterDomainWithPaidPlan ? .registerWithPaidPlan : .purchaseWithPaidPlan
        var destinations: [SiteDomainsPresentationCard.Destination] = [
            .init(
                title: TextContent.primaryButtonTitle(blog.canRegisterDomainWithPaidPlan),
                style: .primary,
                action: {
                    $isShowingDomainSelectionWithType.onChange(showingDomainSelectionWithType).wrappedValue = primaryDestination
                }
            )
        ]

        if !blog.canRegisterDomainWithPaidPlan {
            destinations.append(
                .init(
                    title: TextContent.firstDomainDirectPurchaseButtonTitle,
                    style: .tertiary,
                    action: {
                        $isShowingDomainSelectionWithType.onChange(showingDomainSelectionWithType).wrappedValue = .purchaseSeparately
                    }
                )
            )
        }

        return destinations
    }

    /// Instantiates the proper search depending if it's for claiming a free domain with a paid plan or purchasing a new one
    private func makeDomainSearch(for blog: Blog, domainSelectionType: DomainSelectionType, onDismiss: @escaping () -> Void) -> some View {
        return DomainSuggestionViewControllerWrapper(
            blog: blog,
            domainSelectionType: domainSelectionType,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Constants

private extension SiteDomainsView {

    enum TextContent {
        // Navigation bar
        static let navigationTitle = NSLocalizedString("Site Domains", comment: "Title of the Domains Dashboard.")

        // Domains section
        static let additionalRedirectedDomainTitle: String = NSLocalizedString("Add a domain",
                                                                               comment: "Label of the button that starts the purchase of an additional redirected domain in the Domains Dashboard.")
        static let firstFreeDomainWithPaidPlanDomainTitle: String = NSLocalizedString("site.domains.freeDomainWithPaidPlan.title",
                                                                                      value: "Get your domain",
                                                                                      comment: "Title of the card that starts the purchase of the first domain with a paid plan.")
        static let firstFreeDomainWithPaidPlanDomainDescription = NSLocalizedString("site.domains.freeDomainWithPaidPlan.description",
                                                                                    value: "Get a free one-year domain registration or transfer with any annual paid plan.",
                                                                                    comment: "Description for the first domain purchased with a paid plan.")
        static let firstDomainRegistrationTitle: String = NSLocalizedString("Claim your free domain",
                                                                                   comment: "Title of the card that starts the registration of a free domain with a paid plan, in the Domains Dashboard.")
        static let firstDomainRegistrationDescription = NSLocalizedString("You have a free one-year domain registration with your plan.",
                                                                  comment: "Description for the first domain purchased with a paid plan.")
        static let firstDomainRegistrationButtonTitle = NSLocalizedString("Search for a domain",
                                                                    comment: "title of the button that searches the first domain.")

        static let firstDomainDirectPurchaseButtonTitle: String = NSLocalizedString("site.domains.purchaseDirectly.buttons.title",
                                                                                      value: "Just search for a domain",
                                                                                      comment: "Title for a button that opens domain purchasing flow.")
        static let firstDomainWithPaidPlanButtonTitle: String = NSLocalizedString("site.domains.purchaseWithPlan.buttons.title",
                                                                                      value: "Upgrade to a plan",
                                                                                      comment: "Title for a button that opens plan and domain purchasing flow.")

        static func firstDomainTitle(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstDomainRegistrationTitle : firstFreeDomainWithPaidPlanDomainTitle
        }

        static func firstDomainDescription(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstDomainRegistrationDescription : firstFreeDomainWithPaidPlanDomainDescription
        }

        static func additionalDomainTitle(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstDomainRegistrationTitle : additionalRedirectedDomainTitle
        }

        static func primaryButtonTitle(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstDomainRegistrationButtonTitle : firstDomainWithPaidPlanButtonTitle
        }
    }

    struct Metrics {
        static let insets = EdgeInsets(.init(top: .DS.Padding.double, leading: .DS.Padding.double, bottom: .DS.Padding.double, trailing: .DS.Padding.double))
    }
}

final class SiteDomainsViewController: UIHostingController<SiteDomainsView> {

    // MARK: - Properties

    private let domainManagementFeatureFlag = RemoteFeatureFlag.domainManagement
    private let viewModel: SiteDomainsViewModel

    // MARK: - Init

    init(blog: Blog) {
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let domainsService = DomainsService(coreDataStack: ContextManager.shared, wordPressComRestApi: account?.wordPressComRestApi)
        let viewModel = SiteDomainsViewModel(blog: blog, domainsService: domainsService)
        self.viewModel = viewModel
        let context = SiteDomainsView.PresentationContext()
        let view = SiteDomainsView(blog: blog, viewModel: viewModel, context: context)
        super.init(rootView: view)

        context.viewController = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = SiteDomainsView.TextContent.navigationTitle
        self.setupAllDomainsBarButtonItem()
    }

    // MARK: - Setup

    private func setupAllDomainsBarButtonItem() {
        guard BuildSettings.current.brand == .jetpack else {
            return
        }
        guard domainManagementFeatureFlag.enabled() else {
            return
        }
        let title = AllDomainsListViewController.Strings.title
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            let domains = self.viewModel.loadedDomains.filter { !$0.wpcomDomain }
            let allDomainsViewController = AllDomainsListViewController(viewModel: .init(domains: domains))
            self.navigationController?.pushViewController(allDomainsViewController, animated: true)
            WPAnalytics.track(.domainsDashboardAllDomainsTapped)
        }
        self.navigationItem.rightBarButtonItem = .init(title: title, primaryAction: action)
    }
}
