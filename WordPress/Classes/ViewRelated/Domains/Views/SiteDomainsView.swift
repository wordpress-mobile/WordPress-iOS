import SwiftUI
import WordPressKit
import DesignSystem

/// The Site Domains  screen, accessible from My Site
struct SiteDomainsView: View {

    @ObservedObject var blog: Blog
    @State var isShowingDomainSelectionWithType: DomainSelectionType?
    @State var blogService = BlogService(coreDataStack: ContextManager.shared)
    @State var domainsList: [Blog.DomainRepresentation] = []

    // Property observer
    private func showingDomainSelectionWithType(to value: DomainSelectionType?) {
        switch value {
        case .purchaseSeparately, .registerWithPaidPlan:
            WPAnalytics.track(.domainsDashboardAddDomainTapped, properties: WPAnalytics.domainsProperties(for: blog), blog: blog)
        case .none:
            break
        default:
            // TODO: Analytics
            break
        }
    }

    var body: some View {
        List {
            if blog.supports(.domains) {
                makeSiteAddressSection(blog: blog)
            }
            makeDomainsSection(blog: blog)
                .listRowInsets(Metrics.insets)
        }
        .listStyle(InsetGroupedListStyle())
        .buttonStyle(PlainButtonStyle())
        .onTapGesture(perform: { })
        .onAppear {
            updateDomainsList()

            blogService.refreshDomains(for: blog, success: {
                updateDomainsList()
            }, failure: nil)
        }
        .sheet(item: $isShowingDomainSelectionWithType, content: { domainSelectionType in
            makeDomainSearch(for: blog, domainSelectionType: domainSelectionType, onDismiss: {
                isShowingDomainSelectionWithType = nil
                blogService.refreshDomains(for: blog, success: {
                    updateDomainsList()
                }, failure: nil)
            })
        })
    }

    @ViewBuilder
    private func makeDomainsSection(blog: Blog) -> some View {
        if blog.hasDomains {
            makeDomainsListSection(blog: blog)
        } else {
            makeGetFirstDomainSection(blog: blog)
        }
    }

    /// Builds the site address section for the given blog
    private func makeSiteAddressSection(blog: Blog) -> some View {
        Section(footer: Text(TextContent.primarySiteSectionFooter(blog.hasPaidPlan))) {
            VStack(alignment: .leading) {
                Text(TextContent.siteAddressTitle)
                Text(blog.freeSiteAddress)
                    .bold()
                if blog.freeDomainIsPrimary {
                    ShapeWithTextView(title: TextContent.primaryAddressLabel)
                        .smallRoundedRectangle()
                }
            }
        }
    }

    @ViewBuilder
    private func makeDomainCell(domain: Blog.DomainRepresentation) -> some View {
        VStack(alignment: .leading) {
            Text(domain.domain.domainName)
            if domain.domain.isPrimaryDomain {
                ShapeWithTextView(title: TextContent.primaryAddressLabel)
                    .smallRoundedRectangle()
            }
            makeExpiryRenewalLabel(domain: domain)
        }
    }

    /// Builds the domains list section with the` add a domain` button at the bottom, for the given blog
    private func makeDomainsListSection(blog: Blog) -> some View {
        Section(header: Text(TextContent.domainsListSectionHeader)) {
            ForEach(domainsList) {
                makeDomainCell(domain: $0)
            }
            if blog.supports(.domains) {
                DSButton(
                    title: TextContent.additionalDomainTitle(blog.canRegisterDomainWithPaidPlan),
                    style: .init(
                        emphasis: .tertiary,
                        size: .small,
                        isJetpack: AppConfiguration.isJetpack
                    )) {
                        $isShowingDomainSelectionWithType.onChange(showingDomainSelectionWithType).wrappedValue = .registerWithPaidPlan
                    }
            }
        }
    }

    /// Builds the Get New Domain section when no othert domains are present for the given blog
    private func makeGetFirstDomainSection(blog: Blog) -> some View {
        return Section {
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

    private var siteAddressForGetFirstDomainSection: String {
        blog.canRegisterDomainWithPaidPlan ? "" : blog.freeSiteAddress
    }

    private func makeExpiryRenewalLabel(domain: Blog.DomainRepresentation) -> some View {
        let stringForDomain = DomainExpiryDateFormatter.expiryDate(for: domain.domain)

        return Text(stringForDomain)
                .font(.subheadline)
                .foregroundColor(domain.domain.expirySoon || domain.domain.expired ? Color(UIColor.error) : Color(UIColor.textSubtle))
    }

    /// Instantiates the proper search depending if it's for claiming a free domain with a paid plan or purchasing a new one
    private func makeDomainSearch(for blog: Blog, domainSelectionType: DomainSelectionType, onDismiss: @escaping () -> Void) -> some View {
        return DomainSuggestionViewControllerWrapper(
            blog: blog,
            domainSelectionType: domainSelectionType,
            onDismiss: onDismiss
        )
    }

    private func updateDomainsList() {
        domainsList = blog.domainsList
    }
}

// MARK: - Constants

private extension SiteDomainsView {

    enum TextContent {
        // Navigation bar
        static let navigationTitle = NSLocalizedString("Site Domains", comment: "Title of the Domains Dashboard.")
        // Site address section
        static func primarySiteSectionFooter(_ paidPlan: Bool) -> String {
            paidPlan ? "" : NSLocalizedString("Your primary site address is what visitors will see in their address bar when visiting your website.",
                                                                        comment: "Footer of the primary site section in the Domains Dashboard.")
        }

        static let siteAddressTitle = NSLocalizedString("Your free WordPress.com address is",
                                                        comment: "Title of the site address section in the Domains Dashboard.")
        static let primaryAddressLabel = NSLocalizedString("Primary site address",
                                                           comment: "Primary site address label, used in the site address section of the Domains Dashboard.")

        // Domains section
        static let domainsListSectionHeader: String = NSLocalizedString("Your Site Domains",
                                                                              comment: "Header of the domains list section in the Domains Dashboard.")
        static let paidPlanDomainSectionFooter: String = NSLocalizedString("All WordPress.com plans include a custom domain name. Register your free premium domain now.",
                                                                           comment: "Footer of the free domain registration section for a paid plan.")

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
        static let insets = EdgeInsets(.init(top: Length.Padding.double, leading: Length.Padding.double, bottom: Length.Padding.double, trailing: Length.Padding.double))
    }
}

final class SiteDomainsViewController: UIHostingController<SiteDomainsView> {

    // MARK: - Properties

    private let domainManagementFeatureFlag = RemoteFeatureFlag.domainManagement

    // MARK: - Init

    init(blog: Blog) {
        super.init(rootView: .init(blog: blog))
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
#if JETPACK
        guard domainManagementFeatureFlag.enabled() else {
            return
        }
        let title = AllDomainsListViewController.Strings.title
        let action = UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(AllDomainsListViewController(), animated: true)
            WPAnalytics.track(.domainsDashboardAllDomainsTapped)
        }
        self.navigationItem.rightBarButtonItem = .init(title: title, primaryAction: action)
#endif
    }
}
