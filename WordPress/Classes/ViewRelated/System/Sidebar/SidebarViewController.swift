import UIKit
import SwiftUI
import Combine
import WordPressKit
import WordPressUI

/// The sidebar for the iPad version of the app.
final class SidebarViewController: UIHostingController<AnyView> {
    private let viewModel: SidebarViewModel

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AnyView(SidebarView(viewModel: viewModel, blogListViewModel: viewModel.blogListViewModel)))
        self.title = Strings.sectionMySites
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.onAppear()
    }
}

private struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @ObservedObject var blogListViewModel: BlogListViewModel
    @StateObject private var notificationsButtonViewModel = NotificationsButtonViewModel()

    static let displayedSiteLimit = 4

    var body: some View {
        let list = List(selection: $viewModel.selection) {
            if !blogListViewModel.searchText.isEmpty {
                searchResults
            } else {
                Section {
                    siteListSectionContent
                }
                Section(Strings.moreSection) {
                    more
                }
            }
        }
        .listStyle(.sidebar)
        .accessibilityIdentifier("sidebar_list")
        .tint(AppColor.tint)
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
    private var siteListSectionContent: some View {
        let topSites = blogListViewModel.topSites
        if topSites.isEmpty {
            Label(Strings.createSite, systemImage: "plus.circle")
                .tag(SidebarSelection.welcome)
        } else {
            makeSiteList(with: topSites)
            if blogListViewModel.allSites.count > SidebarView.displayedSiteLimit {
                GeometryReader { proxy in
                    Button {
                        viewModel.navigate(.allSites(sourceRect: proxy.frame(in: .global)))
                    } label: {
                        Label(Strings.allSites, systemImage: "rectangle.stack")
                    }
                    .tint(Color.primary)
                }
            }
            addSiteView
                .tint(Color.primary)
        }
    }

    private func makeSiteList(with sites: [BlogListSiteViewModel]) -> some View {
        ForEach(sites) { site in
            BlogListSiteView(site: site, style: .sidebar)
                .environment(\.siteIconBackgroundColor, Color(.systemBackground))
                .tag(SidebarSelection.blog(site.id))
                .listRowInsets(EdgeInsets(top: 9, leading: 8, bottom: 9, trailing: 8))
        }
    }

    @ViewBuilder
    private var addSiteView: some View {
        let viewModel = AddSiteMenuViewModel(onSelection: { [weak viewModel] in
            viewModel?.navigate(.addSite(selection: $0))
        })
        let label = SidebarAddButtonLabel(title: Strings.addSite)
        switch viewModel.actions.count {
        case 0:
            EmptyView()
        case 1:
            Button(action: viewModel.actions[0].handler) { label }
        default:
            Menu {
                ForEach(viewModel.actions) { action in
                    Button(action.title, action: action.handler)
                }
            } label: { label }
        }
    }

    // MARK: - More

    @ViewBuilder
    private var more: some View {
#if IS_JETPACK
        Label {
            Text(Strings.notifications)
        } icon: {
            if notificationsButtonViewModel.counter > 0 {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.red, Color(UIAppColor.brand))
            } else {
                Image(systemName: "bell")
            }
        }
        .accessibilityIdentifier("sidebar_notifications")
        .tag(SidebarSelection.notifications)

        Label(Strings.reader, systemImage: "eyeglasses")
            .tag(SidebarSelection.reader)
            .accessibilityIdentifier("sidebar_reader")

        if RemoteFeatureFlag.domainManagement.enabled() {
            Button(action: { viewModel.navigate(.domains) }) {
                Label(Strings.domains, systemImage: "network")
            }
            .accessibilityIdentifier("sidebar_domains")
        }
        Button(action: { viewModel.navigate(.help) }) {
            Label(Strings.help, systemImage: "questionmark.circle")
        }
        .accessibilityIdentifier("sidebar_help")
#else
        Button(action: { viewModel.navigate(.help) }) {
            Label(Strings.help, systemImage: "questionmark.circle")
        }
        .accessibilityIdentifier("sidebar_help")
#endif
    }
}

private struct SidebarProfileContainerView: View {
    @ObservedObject var viewModel: SidebarViewModel
    @Environment(\.isSearching) private var isSearching // placemenet is important

    var body: some View {
        if !isSearching {
            content
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color(uiColor: .secondarySystemBackground))
        }
    }

    @ViewBuilder
    var content: some View {
        if let account = viewModel.account {
            Button(action: { viewModel.navigate(.profile) }) {
                SidebarProfileView(account: account)
            }
            .containerShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityIdentifier("sidebar_me")
        } else {
            HStack {
                if AppConfiguration.isJetpack {
                    Button(action: { viewModel.navigate(.signIn) }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Sign In")
                                    .font(.subheadline.weight(.medium))
                                Text("WordPress.com")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(Color(UIAppColor.brand))
                }

                Spacer()

                Button(action: { viewModel.navigate(.profile) }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(Color.secondary)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("sidebar_me")
            }
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

struct SidebarAddButtonLabel: View {
    let title: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: "plus.square.fill")
                .foregroundStyle(AppColor.brand, Color(.secondarySystemFill))
                .font(.title2)
        }
    }
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "Sites", comment: "Sidebar section title on iPad")
    static let moreSection = NSLocalizedString("sidebar.moreSectionTitle", value: "More", comment: "Sidebar section title on iPad")
    static let allSites = NSLocalizedString("sidebar.allSites", value: "All Sites", comment: "Sidebar button title on iPad")
    static let addSite = NSLocalizedString("sidebar.addSite", value: "Add Site", comment: "Sidebar button title on iPad")
    static let createSite = NSLocalizedString("sidebar.createSite", value: "Create Site", comment: "Sidebar button title on iPad")
    static let notifications = NSLocalizedString("sidebar.notifications", value: "Notifications", comment: "Sidebar item on iPad")
    static let reader = NSLocalizedString("sidebar.reader", value: "Reader", comment: "Sidebar item on iPad")
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
    static let help = NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad")
    static let me = NSLocalizedString("sidebar.me", value: "Me", comment: "Sidebar item on iPad")
}
