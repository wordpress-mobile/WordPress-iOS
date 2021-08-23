import SwiftUI

/// The Domains dashboard screen, accessible from My Site
struct DomainsDashboardView: View {
    @State private var showingPaidPlanDomainRegistration = false
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
                    Text(TextContent.redirectedDomainsLabel)
                }

                // register a free domain with a paid plan
                if (blog.isHostedAtWPcom || blog.isAtomic()) && blog.hasDomainCredit {

                    makeSectionPadding()

                    Section(footer: Text(TextContent.paidPlanDomainSectionFooter)) {
                        /// - TODO: DOMAINS - We keep both options at the moment, for testing purposes. We will need to remove the one that we choose not to use.
                        NavigationLink(destination: DomainSuggestionViewControllerWrapper(blog: blog)) {
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

    /// - TODO: - DOMAINS - At the moment there are a few issues with the modal presentation, so this is currently not used.
    /// Adds an action that presents the domain registration flow modally
    /// - Parameter site: the current site
    /// - Returns: the view that presents the flow modallty
    private func makeButtonForModalRegistration(site: JetpackSiteRef) -> some View {
        Button(TextContent.paidPlanRegistrationLabelModal) {
            showingPaidPlanDomainRegistration.toggle()
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPaidPlanDomainRegistration) {
            NavigationView {
                if #available(iOS 14.0, *) {
                    DomainSuggestionViewControllerWrapper(blog: blog)
                        .navigationTitle(TextContent.paidPlanRegistrationNavigationTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarItems(leading: Button(TextContent.paidPlanModalCancelButtonTitle,
                                                            action: {
                                                                showingPaidPlanDomainRegistration = false
                                                            }))
                } else {
                    DomainSuggestionViewControllerWrapper(blog: blog)
                        /// - TODO: DOMAINS - This will likely need to be refactored for iOS 13, if we keep supporting it.
                        .navigationBarItems(leading: Button(TextContent.paidPlanModalCancelButtonTitle,
                                                            action: {
                                                                showingPaidPlanDomainRegistration = false
                                                            }))
                }
            }
        }
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
        /// - TODO: DOMAINS - This title needs to be reviewed
        static let redirectedDomainsLabel: String = NSLocalizedString("New domain flow",
                                                                      comment: "Label of the button that starts the purchase of a new redirected domain in the Domains Dashboard.")

        // paid plans
        static let paidPlanDomainSectionFooter: String = NSLocalizedString("All WordPress.com plans include a custom domain name. Register your free premium domain now.",
                                                                           comment: "Footer of the free domain registration section for a paid plan.")
        static let paidPlanRegistrationLabelNavigation: String = NSLocalizedString("Register a free domain",
                                                                                   comment: "Label of the button that starts the registration of a free domain with a paid plan, in the Domains Dashboard.")
        /// - TODO: - DOMAINS - At the moment there are a few issues with the modal presentation, so this is currently not used.
        static let paidPlanRegistrationLabelModal: String = NSLocalizedString("Register a free domain - modal presentation",
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
