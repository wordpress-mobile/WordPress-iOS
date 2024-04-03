import SwiftUI
import DesignSystem

struct BlogListView: View {
    private enum Constants {
        static let imageDiameter: CGFloat = 40
    }

    struct Site: Equatable {
        let title: String
        let domain: String
        let imageURL: URL?
    }

    @Binding private var isEditing: Bool
    @Binding private var isSearching: Bool
    @State private var pinnedDomains: [String]
    @State private var recentDomains: [String]
    private let sites: [Site]
    private let currentDomain: String?
    private let selectionCallback: ((String) -> Void)

    init(
        sites: [Site],
        currentDomain: String?,
        isEditing: Binding<Bool>,
        isSearching: Binding<Bool>,
        selectionCallback: @escaping ((String) -> Void)
    ) {
        self.sites = sites
        self.currentDomain = currentDomain
        self.pinnedDomains = BlogListReducer.pinnedDomains().compactMap({ $0.domain })
        self.recentDomains = BlogListReducer.recentDomains()
        self._isEditing = isEditing
        self._isSearching = isSearching
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
                ForEach(sites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } else {
                pinnedSection
                recentsSection
                allSitesSection
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
        let pinnedSites = BlogListReducer.pinnedSites(
            allSites: sites,
            pinnedDomains: pinnedDomains
        )
        if !pinnedSites.isEmpty {
            Section {
                ForEach(pinnedSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: "Pinned sites"
                )
                .listRowInsets(EdgeInsets(
                    top: .DS.Padding.medium,
                    leading: .DS.Padding.double,
                    bottom: 0,
                    trailing: .DS.Padding.double)
                )
            }
        }
    }

    @ViewBuilder
    private var allSitesSection: some View {
        let allSites = BlogListReducer.allSites(
            allSites: sites,
            pinnedDomains: pinnedDomains,
            recentDomains: recentDomains
        )
        if !allSites.isEmpty {
            Section {
                ForEach(allSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: "All sites"
                )
            }
        }
    }

    @ViewBuilder
    private var recentsSection: some View {
        let recentSites = BlogListReducer.recentSites(
            allSites: sites,
            recentDomains: recentDomains
        )
        if !recentSites.isEmpty {
            Section {
                ForEach(recentSites, id: \.domain) { site in
                    siteButton(site: site)
                }
            } header: {
                sectionHeader(
                    title: "Recent sites"
                )
            }
        }
    }

    private func siteButton(site: Site) -> some View {
        Button {
            if isEditing {
                withAnimation {
                    BlogListReducer.toggleDomainPin(domain: site.domain)
                    pinnedDomains = BlogListReducer.pinnedDomains().compactMap({ $0.domain })
                    recentDomains = BlogListReducer.recentDomains()
                }
            } else {
                BlogListReducer.didSelectDomain(domain: site.domain)
                selectionCallback(site.domain)
            }
        } label: {
            siteHStack(site: site)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(
            currentDomain == site.domain
            ? Color.DS.Background.secondary
            : Color.DS.Background.primary
        )
    }

    private func siteHStack(site: Site) -> some View {
        HStack(spacing: 0) {
            AvatarsView(style: .single(site.imageURL))
                .padding(.trailing, .DS.Padding.split)

            textsVStack(title: site.title, domain: site.domain)

            Spacer()

            if isEditing {
                pinIcon(
                    domain: site.domain
                )
                .padding(.trailing, .DS.Padding.double)
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

    private func pinIcon(domain: String) -> some View {
        if pinnedDomains.contains(domain) == true {
            Image(systemName: "pin.fill")
                .imageScale(.small)
                .foregroundStyle(Color.DS.Background.brand(isJetpack: true))
        } else {
            Image(systemName: "pin")
                .imageScale(.small)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }

}
