import UIKit
import SwiftUI

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
    case domain
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
        .searchable(text: $blogListViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
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
    }

    private func makeMenuItem(_ title: String, image: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(image).renderingMode(.template)
        }
    }
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "My Sites", comment: "Sidebar section title on iPad")
    static let moreSection = NSLocalizedString("sidebar.moreSectionTitle", value: "More", comment: "Sidebar section title on iPad")
    static let notifications = NSLocalizedString("sidebar.notifications", value: "Notifications", comment: "Sidebar item on iPad")
    static let reader = NSLocalizedString("sidebar.reader", value: "Reader", comment: "Sidebar item on iPad")
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
}
