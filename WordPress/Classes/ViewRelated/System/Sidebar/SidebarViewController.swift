import UIKit
import SwiftUI
import Combine
import WordPressKit
import WordPressUI

/// The sidebar for the iPad version of the app.
final class SidebarViewController: UIHostingController<AnyView> {
    init(viewModel: SidebarViewModel) {
        super.init(rootView: AnyView(SidebarView(viewModel: viewModel)))
        self.title = Strings.sectionMySites
        self.navigationItem.largeTitleDisplayMode = .always
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

private struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @StateObject private var blogListViewModel = BlogListViewModel()

    var body: some View {
        // TODO: (wpsidebar) add a way to see all sites
        List(selection: $viewModel.selection) {
            if !blogListViewModel.searchText.isEmpty {
                searchResults
            } else {
                Section {
                    makeSiteListSection(with: blogListViewModel)
                }
                Section(Strings.moreSection) {
                    more
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            SidebarProfileContainerView(viewModel: viewModel)
        }
        // TODO: (wpsidebar) show searchable only if there is more than visible # of sites
        .searchable(text: $blogListViewModel.searchText, placement: .sidebar)
    }

    @ViewBuilder
    var searchResults: some View {
        if blogListViewModel.searchResults.isEmpty {
            EmptyStateView.search()
        } else {
            makeSiteList(with: blogListViewModel.searchResults)
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
        Menu {
            Text("Not Implemented")
        } label: {
            Label(Strings.addSite, systemImage: "plus.circle")
        }
    }

    private func makeSiteList(with sites: [BlogListSiteViewModel]) -> some View {
        ForEach(sites) { site in
            // TODO: udpate background color
            BlogListSiteView(site: site)
                .tag(SidebarSelection.blog(site.id))
        }
    }

    // MARK: - More

    @ViewBuilder
    private var more: some View {
        Group {
            Label(Strings.notifications, systemImage: "bell")
                .tag(SidebarSelection.notifications)
            Label(Strings.reader, systemImage: "eyeglasses")
                .tag(SidebarSelection.reader)
            Label(Strings.domains, systemImage: "network")
                .tag(SidebarSelection.domains)
            Label(Strings.help, systemImage: "questionmark.circle")
                .tag(SidebarSelection.help)
        }
        .foregroundStyle(.primary)
    }
}

private struct SidebarProfileContainerView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @Environment(\.isSearching) private var isSearching // placemenet is important

    var body: some View {
        if let account = viewModel.account, !isSearching {
            Button(action: viewModel.showProfileDetails) {
                SidebarProfileView(account: account)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.top, 8)
            .background(Color(uiColor: .secondarySystemBackground))
        }
    }
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "Sites", comment: "Sidebar section title on iPad")
    static let moreSection = NSLocalizedString("sidebar.moreSectionTitle", value: "More", comment: "Sidebar section title on iPad")
    static let addSite = NSLocalizedString("sidebar.addSite", value: "Add Site", comment: "Sidebar button title on iPad")
    static let notifications = NSLocalizedString("sidebar.notifications", value: "Notifications", comment: "Sidebar item on iPad")
    static let reader = NSLocalizedString("sidebar.reader", value: "Reader", comment: "Sidebar item on iPad")
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
    static let help = NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad")
}
