import SwiftUI
import DesignSystem
import WordPressUI

struct BlogListView: View {
    @ObservedObject var viewModel: BlogListViewModel

    let onSiteSelected: ((Blog) -> Void)

    var body: some View {
        List {
            if !viewModel.searchText.isEmpty {
                makeSiteList(with: viewModel.searchResults)
            } else {
                listContent
            }
        }
        .refreshable {
            try? await viewModel.refresh()
        }
        .environment(\.defaultMinListRowHeight, 30) // For custom section headers
        .listStyle(.plain)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isShowingRecentSites {
            makeSection(title: Strings.recentsSectionTitle, sites: viewModel.recentSites)
            makeSection(title: Strings.allSitesSectionTitle, sites: viewModel.allSites, spacing: 12)
        } else {
            makeSiteList(with: viewModel.allSites)
        }
    }

    @ViewBuilder
    private func makeSection(title: String, sites: [BlogListSiteViewModel], spacing: CGFloat = 0) -> some View {
        // We don't want these to be sticky, so titles are rendered as regular cells
        Text(title)
            .font(.headline)
            .listRowSeparator(.hidden)
            .padding(.top, spacing)

        makeSiteList(with: sites)
    }

    private func makeSiteList(with sites: [BlogListSiteViewModel]) -> some View {
        ForEach(sites) { site in
            makeSiteView(with: site)
                .listRowSeparator(site.id == sites.first?.id ? .hidden : .automatic, edges: .top)
                .listRowSeparator(site.id == sites.last?.id ? .hidden : .automatic, edges: .bottom)
        }
    }

    @ViewBuilder
    private func makeSiteView(with site: BlogListSiteViewModel) -> some View {
        let view = Button {
            if let site = viewModel.didSelectSite(withID: site.id.objectID) {
                onSiteSelected(site)
            }
        } label: {
            BlogListSiteView(site: site)
        }
        if let siteURL = site.siteURL {
            view.swipeActions(edge: .leading) {
                Button(SharedStrings.Button.view, systemImage: "safari", action: site.buttonViewTapped)
                    .tint(Color.blue)
            }
            .swipeActions(edge: .trailing) {
                ShareLink(item: siteURL)
            }
            .contextMenu {
                Button(SharedStrings.Button.view, systemImage: "safari", action: site.buttonViewTapped)
                Button(SharedStrings.Button.copyLink, systemImage: "doc.on.doc", action: site.buttonCopyLinkTapped)
                ShareLink(item: siteURL)
            } preview: {
                WebView(url: siteURL)
            }
        } else {
            view
        }
    }
}

private extension BlogListView {
    enum Strings {
        static let recentsSectionTitle = NSLocalizedString(
            "sitePicker.recentSitesSectionTitle",
            value: "Recent sites",
            comment: "Recents section title for site switcher."
        )

        static let allSitesSectionTitle = NSLocalizedString(
            "sitePicker.allSitesSectionTitle",
            value: "All sites",
            comment: "All sites section title for site switcher."
        )
    }
}
