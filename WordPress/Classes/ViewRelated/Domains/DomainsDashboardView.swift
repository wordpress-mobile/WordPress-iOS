import SwiftUI

/// The Domains dashboard screen, accessible from My Site
struct DomainsDashboardView: View {
    @ObservedObject var blog: Blog

    var body: some View {
        makeList(blog: blog)
    }

    /// Builds the main list of the view
    /// - Parameter blog: the given blog
    private func makeList(blog: Blog) -> some View {
        List {
            // primary site address
            if let urlString = blog.displayURL {
                Section(header: Text(TextContent.primarySiteSectionHeader),
                        footer: Text(TextContent.primarySiteSectionFooter)) {
                    Text("\(urlString)")
                }

                makeSectionPadding()

                // register a free domain
                Section(header: Text(TextContent.redirectedDomainsSectionHeader)) {
                    /// - TODO: - DOMAINS - Add the action that will start the new domain registration flow here
                    NavigationLink(destination: DomainSuggestionViewControllerWrapper(blog: blog, domainType: .siteRedirect)) {
                        /// - TODO: - DOMAINS - adjust the title depending on wether there is already a redirected domain or not
                        Text(TextContent.firstRedirectedDomainLabel)
                    }
                }

                // register a free domain with a paid plan
                if (blog.isHostedAtWPcom || blog.isAtomic()) && blog.hasDomainCredit {

                    makeSectionPadding()

                    Section(footer: Text(TextContent.paidPlanDomainSectionFooter)) {
                        /// - TODO: DOMAINS - We keep both options at the moment, for testing purposes. We will need to remove the one that we choose not to use.
                        NavigationLink(destination: DomainSuggestionViewControllerWrapper(blog: blog, domainType: .registered)) {
                            Text(TextContent.paidPlanRegistrationLabelNavigation)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }

    /// Creates an "empty" section to be used as a padding between sections
    /// - Parameter idealHeight: the ideal height of the padding
    /// - Returns: the view that creates the padding
    private func makeSectionPadding(idealHeight: CGFloat = Metrics.sectionPaddingDefaultHeight) -> some View {
        Section {
            EmptyView()
        }
        .frame(idealHeight: idealHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Constants
private extension DomainsDashboardView {

    enum TextContent {
        // primary site
        static let primarySiteSectionHeader: String = NSLocalizedString("Primary Site Address",
                                                                        comment: "Header of the primary site section in the Domains dashboard.")
        static let primarySiteSectionFooter: String = NSLocalizedString("Your primary site address is what visitors will see in their address bar when visiting your website.",
                                                                         comment: "Footer of the primary site section in the Domains dashboard.")

        // redirected domains
        static let redirectedDomainsSectionHeader: String = NSLocalizedString("Redirected Domains",
                                                                              comment: "Header of the redirected domains section in the Domains Dashboard.")
        // button title when adding the first redirected domain
        static let firstRedirectedDomainLabel: String = NSLocalizedString("Get your domain",
                                                                      comment: "Label of the button that starts the purchase of a the first redirected domain in the Domains Dashboard.")

        // button title when adding another redirected domain
        static let additionalRedirectedDomainLabel: String = NSLocalizedString("Add a domain",
                                                                               comment: "Label of the button that starts the purchase of an additional redirected domain in the Domains Dashboard.")

        // paid plans
        static let paidPlanDomainSectionFooter: String = NSLocalizedString("All WordPress.com plans include a custom domain name. Register your free premium domain now.",
                                                                           comment: "Footer of the free domain registration section for a paid plan.")
        static let paidPlanRegistrationLabelNavigation: String = NSLocalizedString("Register a free domain",
                                                                                   comment: "Label of the button that starts the registration of a free domain with a paid plan, in the Domains Dashboard.")
        static let paidPlanRegistrationNavigationTitle: String = NSLocalizedString("Register Domain",
                                                                                   comment: "Navigation bar title of the free domain registration flow, used in the Domains Dashboard.")

        static let paidPlanModalCancelButtonTitle: String = NSLocalizedString("Cancel",
                                                                              comment: "Title of the cancel button in the modal presentation of the domain registration flow, used in Domains Dashboard.")
    }

    enum Metrics {
        static let sectionPaddingDefaultHeight: CGFloat = 16.0
    }
}
