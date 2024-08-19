import UIKit
import SwiftUI
import WordPressKit
import Combine

/// The sidebar dispalyed on the iPad.
final class SidebarViewController: UIHostingController<SidebarView> {
    init(viewModel: SidebarViewModel) {
        super.init(rootView: SidebarView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum SidebarSelection: Hashable {
    case empty // No sites
    case blog(TaggedManagedObjectID<Blog>)
    case notifications
    case reader
    case domains
    case help
}

struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @StateObject private var blogListViewModel = BlogListViewModel()

    var body: some View {
        // TODO: (wpsidebar) add a way to see all sites
        List(selection: $viewModel.selection) {
            Section(Strings.sectionMySites) {
                makeSiteListSection(with: blogListViewModel)
            }
            Section(Strings.moreSection) {
                more
            }
        }
        .listStyle(.sidebar)
        // TODO: (wpsidebar) show searchable only if there is more than visible # of sites
        .searchable(text: $blogListViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .safeAreaInset(edge: .bottom) {
            if let account = viewModel.account {
                Button(action: viewModel.showProfileDetails) {
                    SidebarProfileView(account: account)
                }
                .buttonStyle(.plain)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
            }
        }
    }

    // MARK: - My Sites

    // TODO: (wpsidebar) add support for recent sites
    @ViewBuilder
    private func makeSiteListSection(with viewModel: BlogListViewModel) -> some View {
        if !viewModel.searchText.isEmpty {
            makeSiteList(with: viewModel.searchResults)
        } else if !viewModel.allSites.isEmpty {
            makeSiteList(with: viewModel.allSites)
        } else {
            // TODO: (wpsidebar) handle no-sites scenarios
            Text("–")
        }
    }

    private func makeSiteList(with sites: [BlogListSiteViewModel]) -> some View {
        ForEach(sites) { site in
            BlogListSiteView(site: site)
                .tag(SidebarSelection.blog(site.id))
        }
    }

    @ViewBuilder
    private func makeSiteView(with site: BlogListSiteViewModel) -> some View {
        BlogListSiteView(site: site)
    }

    // MARK: - More

    @ViewBuilder
    private var more: some View {
        makeMenuItem(Strings.notifications, image: "tab-bar-notifications-unselected")
            .tag(SidebarSelection.notifications)
        makeMenuItem(Strings.reader, image: "tab-bar-reader-unselected")
            .tag(SidebarSelection.reader)
        makeMenuItem(Strings.domains, image: "site-menu-domains")
            .tag(SidebarSelection.domains)
        makeMenuItem(Strings.help, image: "theme-support")
            .tag(SidebarSelection.help)
    }

    private func makeMenuItem(_ title: String, image: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(image).renderingMode(.template)
        }
    }
}

private struct SidebarProfileView: View {
    @ObservedObject var account: WPAccount

    var body: some View {
        HStack {
            let avatarURL: String? = account.avatarURL
            AvatarsView<Circle>(style: .single(avatarURL.flatMap(URL.init)))

            VStack(alignment: .leading, spacing: 0) {
                Text(account.displayName)
                    .font(.callout.weight(.medium))
                Text(account.username)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "gearshape")
                .foregroundColor(Color.secondary.opacity(0.7))
        }
    }
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
    @Published var account: WPAccount?

    var showProfileDetails: () -> Void = {}

    init() {
        // TODO: (wpsidebar) can it change during the root presenter lifetime?
        self.account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "My Sites", comment: "Sidebar section title on iPad")
    static let moreSection = NSLocalizedString("sidebar.moreSectionTitle", value: "More", comment: "Sidebar section title on iPad")
    static let notifications = NSLocalizedString("sidebar.notifications", value: "Notifications", comment: "Sidebar item on iPad")
    static let reader = NSLocalizedString("sidebar.reader", value: "Reader", comment: "Sidebar item on iPad")
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
    static let help = NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad")
}
