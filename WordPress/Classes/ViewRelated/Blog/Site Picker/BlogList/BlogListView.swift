import SwiftUI
import DesignSystem

struct BlogListView: View {
    private enum Constants {
        static let imageDiameter: CGFloat = 40
    }

    struct Site: Equatable {
        let id: NSNumber?
        let title: String
        let domain: String
        let imageURL: URL?
    }

    @Binding private var isEditing: Bool
    @Binding private var isSearching: Bool
    @Binding private var searchText: String
    @StateObject var viewModel: BlogListViewModel = BlogListViewModel()
    @State private var pressedDomains: Set<String> = []
    private let selectionCallback: ((NSNumber) -> Void)

    init(
        isEditing: Binding<Bool>,
        isSearching: Binding<Bool>,
        searchText: Binding<String>,
        selectionCallback: @escaping ((NSNumber) -> Void)
    ) {
        self._isEditing = isEditing
        self._isSearching = isSearching
        self._searchText = searchText
        self.selectionCallback = selectionCallback
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            contentVStack
                .scrollContentBackground(.hidden)
        } else {
            contentVStack
        }
    }

    private var contentVStack: some View {
        List {
            if isSearching {
                ForEach(viewModel.searchSites, id: \.id) { site in
                    siteButton(site: site)
                }
                .onChange(of: searchText) { newValue in
                    viewModel.updateSearchText(newValue)
                }
            } else {
                pinnedSection
                recentsSection
                allRemainingSitesSection
            }
        }
        .listStyle(.grouped)
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .style(.bodyLarge(.emphasized))
            .foregroundStyle(Color.DS.Foreground.primary)
            .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var pinnedSection: some View {
        if !viewModel.pinnedSites.isEmpty {
            Section {
                ForEach(viewModel.pinnedSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: Strings.pinnedSectionTitle
                )
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: .DS.Padding.double,
                    bottom: .DS.Padding.half,
                    trailing: .DS.Padding.double)
                )
            }
        }
    }

    @ViewBuilder
    private var allRemainingSitesSection: some View {
        if !viewModel.allRemainingSites.isEmpty {
            Section {
                ForEach(viewModel.allRemainingSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: Strings.allRemainingSitesSectionTitle
                )
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: .DS.Padding.double,
                    bottom: .DS.Padding.half,
                    trailing: .DS.Padding.double)
                )
            }
        }
    }

    @ViewBuilder
    private var recentsSection: some View {
        if !viewModel.recentSites.isEmpty {
            Section {
                ForEach(viewModel.recentSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: Strings.recentsSectionTitle
                )
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: .DS.Padding.double,
                    bottom: .DS.Padding.half,
                    trailing: .DS.Padding.double)
                )
            }
        }
    }

    @ViewBuilder
    private func siteButton(site: Site) -> some View {
        if let siteID = site.id {
            Button {
                if isEditing {
                    withAnimation {
                        viewModel.togglePinnedSite(siteID: siteID)
                    }
                } else {
                    viewModel.siteSelected(siteID: siteID)
                    selectionCallback(siteID)
                }
            } label: {
                siteHStack(site: site)
            }
            .listRowSeparator(.hidden)
            .buttonStyle(SelectedButtonStyle(onPress: { isPressed in
                pressedDomains = pressedDomains.symmetricDifference([site.domain])
            }))
            .listRowBackground(
                pressedDomains.contains(
                    site.domain
                ) ? Color.DS.Background.secondary : Color.DS.Background.primary
            )
        }
    }

    private func siteHStack(site: Site) -> some View {
        HStack(spacing: 0) {
            AvatarsView(style: .single(site.imageURL))
                .padding(.trailing, .DS.Padding.split)

            textsVStack(title: site.title, domain: site.domain)

            Spacer()

            if isEditing {
                pinIcon(site: site)
            }
        }
    }

    private func textsVStack(title: String, domain: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .style(.bodySmall(.regular))
                .foregroundStyle(Color.DS.Foreground.primary)
                .layoutPriority(1)
                .lineLimit(2)

            Text(domain)
                .style(.bodySmall(.regular))
                .foregroundStyle(Color.DS.Foreground.secondary)
                .layoutPriority(2)
                .lineLimit(1)
                .padding(.top, .DS.Padding.half)
        }
    }

    private func pinIcon(site: Site) -> some View {
        if viewModel.pinnedSites.contains(site) {
            Image(systemName: "pin.fill")
                .foregroundStyle(Color.DS.Background.brand(isJetpack: true))
                .rotationEffect(.degrees(45))
        } else {
            Image(systemName: "pin")
                .foregroundStyle(Color.DS.Foreground.secondary)
                .rotationEffect(.degrees(45))
        }
    }

}

private extension BlogListView {
    enum Strings {
        static let pinnedSectionTitle = NSLocalizedString(
            "site_switcher_pinned_section_title",
            value: "Pinned sites",
            comment: "Pinned section title for site switcher."
        )

        static let recentsSectionTitle = NSLocalizedString(
            "site_switcher_recents_section_title",
            value: "Recent sites",
            comment: "Recents section title for site switcher."
        )

        static let allRemainingSitesSectionTitle = NSLocalizedString(
            "site_switcher_all_sites_section_title",
            value: "All sites",
            comment: "All sites section title for site switcher."
        )
    }
}

private struct SelectedButtonStyle: ButtonStyle {
    var onPress: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                onPress(newValue)
            }
    }
}
