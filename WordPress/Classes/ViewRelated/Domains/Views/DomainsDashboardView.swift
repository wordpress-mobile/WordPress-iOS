import SwiftUI
import WordPressKit

/// The Domains dashboard screen, accessible from My Site
struct DomainsDashboardView: View {
    @ObservedObject var blog: Blog
    @State var isShowingDomainRegistrationFlow = false

    // Property observer
    private func showingDomainRegistrationFlow(to value: Bool) {
        if value {
            WPAnalytics.track(.domainsDashboardAddDomainTapped, properties: WPAnalytics.domainsProperties(for: blog), blog: blog)
        }
    }

    var body: some View {
        List {
            makeSiteAddressSection(blog: blog)
            makeDomainsSection(blog: blog)
        }
        .listStyle(GroupedListStyle())
        .padding(.top, Metrics.topPadding)
        .buttonStyle(PlainButtonStyle())
        .onTapGesture(perform: { })
        .navigationBarTitle(TextContent.navigationTitle)
        .sheet(isPresented: $isShowingDomainRegistrationFlow, content: {
            makeDomainSearch(for: blog, onDismiss: {
                isShowingDomainRegistrationFlow = false
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
        Section(header: makeSiteAddressHeader(),
                footer: Text(TextContent.primarySiteSectionFooter(blog.hasPaidPlan))) {
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
            ForEach(blog.domainsList) {
                makeDomainCell(domain: $0)
            }
            PresentationButton(
                isShowingDestination: $isShowingDomainRegistrationFlow.onChange(showingDomainRegistrationFlow),
                appearance: {
                    HStack {
                        Text(TextContent.additionalDomainTitle(blog.canRegisterDomainWithPaidPlan))
                            .foregroundColor(Color(UIColor.primary))
                            .bold()
                        Spacer()
                    }
                }
            )
        }
    }

    /// Builds the Get New Domain section when no othert domains are present for the given blog
    private func makeGetFirstDomainSection(blog: Blog) -> some View {
        Section {
            PresentationCard(
                title: TextContent.firstDomainTitle(blog.canRegisterDomainWithPaidPlan),
                description: TextContent.firstDomainDescription(blog.canRegisterDomainWithPaidPlan),
                highlight: siteAddressForGetFirstDomainSection,
                isShowingDestination: $isShowingDomainRegistrationFlow.onChange(showingDomainRegistrationFlow)) {
                    ShapeWithTextView(title: TextContent.firstSearchDomainButtonTitle)
                        .largeRoundedRectangle()
                }
        }
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

    private func makeSiteAddressHeader() -> Divider? {
        if #available(iOS 15, *) {
            return nil
        }
        return Divider()
    }

    /// Instantiates the proper search depending if it's for claiming a free domain with a paid plan or purchasing a new one
    private func makeDomainSearch(for blog: Blog, onDismiss: @escaping () -> Void) -> some View {
        return DomainSuggestionViewControllerWrapper(blog: blog, domainType: blog.canRegisterDomainWithPaidPlan ? .registered : .siteRedirect, onDismiss: onDismiss)
    }
}

// MARK: - Constants
private extension DomainsDashboardView {

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

        static let firstRedirectedDomainTitle: String = NSLocalizedString("Get your domain",
                                                                          comment: "Title of the card that starts the purchase of the first redirected domain in the Domains Dashboard.")
        static let firstRedirectedDomainDescription = NSLocalizedString("Domains purchased on this site will redirect users to ",
                                                                  comment: "Description for the first domain purchased with a free plan.")
        static let firstPaidPlanRegistrationTitle: String = NSLocalizedString("Claim your free domain",
                                                                                   comment: "Title of the card that starts the registration of a free domain with a paid plan, in the Domains Dashboard.")
        static let firstPaidPlanRegistrationDescription = NSLocalizedString("You have a free one-year domain registration with your plan",
                                                                  comment: "Description for the first domain purchased with a paid plan.")
        static let firstSearchDomainButtonTitle = NSLocalizedString("Search for a domain",
                                                                    comment: "title of the button that searches the first domain.")

        static func firstDomainTitle(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstPaidPlanRegistrationTitle : firstRedirectedDomainTitle
        }

        static func firstDomainDescription(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstPaidPlanRegistrationDescription : firstRedirectedDomainDescription
        }

        static func additionalDomainTitle(_ canRegisterDomainWithPaidPlan: Bool) -> String {
            canRegisterDomainWithPaidPlan ? firstPaidPlanRegistrationTitle : additionalRedirectedDomainTitle
        }
    }

    enum Metrics {
        static let sectionPaddingDefaultHeight: CGFloat = 16.0
        static let topPadding: CGFloat = -34.0
    }
}
