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
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @StateObject private var blogListViewModel = BlogListViewModel()

    static let displayedSiteLimit = RecentSitesService.maxSiteCount

    var body: some View {
        let list = List(selection: $viewModel.selection) {
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
        .overlay(alignment: .bottom) {
            SidebarProfileContainerView(viewModel: viewModel)
        }
        if blogListViewModel.allSites.count > SidebarView.displayedSiteLimit {
            list.searchable(text: $blogListViewModel.searchText, placement: .sidebar)
        } else {
            list
        }
    }

    @ViewBuilder
    var searchResults: some View {
        if blogListViewModel.searchResults.isEmpty {
            EmptyStateView.search()
        } else {
            makeSiteList(with: blogListViewModel.searchResults)
        }
    }

    // MARK: - Sites

    @ViewBuilder
    private func makeSiteListSection(with viewModel: BlogListViewModel) -> some View {
        let topSites = viewModel.topSites
        if !topSites.isEmpty {
            makeSiteList(with: topSites)
        } else {
            Text(Strings.noSites)
        }
        if viewModel.allSites.count > SidebarView.displayedSiteLimit {
            Menu {
                Text("Not Implemented")
            } label: {
                Label(Strings.allSites, systemImage: "rectangle.stack")
            }
            .tint(Color.primary)
        }
        Menu {
            Text("Not Implemented")
        } label: {
            Label(Strings.addSite, systemImage: "plus.circle")
        }
        .tint(Color.primary)
    }

    private func makeSiteList(with sites: [BlogListSiteViewModel]) -> some View {
        ForEach(sites) { site in
            BlogListSiteView(site: site)
                .environment(\.siteIconBackgroundColor, Color(.systemBackground))
                .tag(SidebarSelection.blog(site.id))
        }
    }

    // MARK: - More

    @ViewBuilder
    private var more: some View {
        Label(Strings.notifications, systemImage: "bell")
            .tag(SidebarSelection.notifications)
        Label(Strings.reader, systemImage: "eyeglasses")
            .tag(SidebarSelection.reader)
        Label(Strings.domains, systemImage: "network")
            .tag(SidebarSelection.domains)
        Label(Strings.help, systemImage: "questionmark.circle")
            .tag(SidebarSelection.help)
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

private extension BlogListViewModel {
    /// Returns the most recent sites and mixes and mixes in the rest of the sites
    /// until the display limimt is reached.
    var topSites: [BlogListSiteViewModel] {
        var topSites = recentSites.prefix(SidebarView.displayedSiteLimit)
        var encounteredIDs = Set(topSites.map(\.id))
        for site in allSites where !encounteredIDs.contains(site.id) {
            if topSites.count >= SidebarView.displayedSiteLimit {
                break
            }
            encounteredIDs.insert(site.id)
            topSites.append(site)
        }
        return Array(topSites).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "Sites", comment: "Sidebar section title on iPad")
    static let moreSection = NSLocalizedString("sidebar.moreSectionTitle", value: "More", comment: "Sidebar section title on iPad")
    static let allSites = NSLocalizedString("sidebar.allSites", value: "All Sites", comment: "Sidebar button title on iPad")
    static let noSites = NSLocalizedString("sidebar.noSites", value: "No Sites", comment: "Sidebar empty state title on iPad")
    static let addSite = NSLocalizedString("sidebar.addSite", value: "Add Site", comment: "Sidebar button title on iPad")
    static let notifications = NSLocalizedString("sidebar.notifications", value: "Notifications", comment: "Sidebar item on iPad")
    static let reader = NSLocalizedString("sidebar.reader", value: "Reader", comment: "Sidebar item on iPad")
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
    static let help = NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad")
}
