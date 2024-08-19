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
    case blog(TaggedManagedObjectID<Blog>)
    case reader
    case notifications
    case domain
    case help
    case profile
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
        }
        .listStyle(.sidebar)
        .searchable(text: $blogListViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

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
}

final class SidebarViewModel: ObservableObject {
    @Published var selection: SidebarSelection?
}

private enum Strings {
    static let sectionMySites = NSLocalizedString("sidebar.mySitesSectionTitle", value: "My Sites", comment: "Sidebar section title on iPad")
}
