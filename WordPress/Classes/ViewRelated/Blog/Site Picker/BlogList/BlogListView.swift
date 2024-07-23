import SwiftUI
import DesignSystem

struct BlogListView: View {
    @StateObject var viewModel = BlogListViewModel()

    @Binding private var isSearching: Bool
    @Binding private var searchText: String

    private let onSiteSelected: ((Blog) -> Void)

    init(
        isSearching: Binding<Bool>,
        searchText: Binding<String>,
        onSiteSelected: @escaping ((Blog) -> Void)
    ) {
        self._isSearching = isSearching
        self._searchText = searchText
        self.onSiteSelected = onSiteSelected
    }

    var body: some View {
        List {
            if !searchText.isEmpty {
                makeSiteList(with: viewModel.searchResults)
            } else {
                listContent
            }
        }
        .environment(\.defaultMinListRowHeight, 30) // For custom section headers
        .listStyle(.plain)
        .onChange(of: searchText) { newValue in
            viewModel.searchQueryChanged(newValue)
        }
        .onAppear {
            viewModel.viewAppeared()
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.allSites.count > 12 {
            if !viewModel.recentSites.isEmpty {
                makeSection(title: Strings.recentsSectionTitle, sites: viewModel.recentSites)
            }
            if !viewModel.allSites.isEmpty {
                makeSection(title: Strings.allSitesSectionTitle, sites: viewModel.allSites, spacing: viewModel.recentSites.isEmpty ? 0 : 16)
            }
        } else {
            // Too few sites to bother with "Recent"
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
            Button {
                if let site = viewModel.didSelectSite(withSiteID: site.id) {
                    onSiteSelected(site)
                }
            } label: {
                BlogListSiteView(site: site)
            }
            .listRowSeparator(site.id == sites.first?.id ? .hidden : .automatic, edges: .top)
            .listRowSeparator(site.id == sites.last?.id ? .hidden : .automatic, edges: .bottom)
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
