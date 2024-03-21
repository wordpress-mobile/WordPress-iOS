import SwiftUI
import DesignSystem

struct BlogListView: View {
    private enum Constants {
        static let imageDiameter: CGFloat = 40
    }

    struct Site {
        let title: String
        let domain: String
        let imageURL: URL?
    }

    @Binding private var isEditing: Bool
    @Binding private var pinnedDomains: Set<String>
    private let sites: [Site]
    private let selectionCallback: ((String) -> Void)

    init(
        sites: [Site],
        pinnedDomains: Binding<Set<String>>,
        isEditing: Binding<Bool>,
        selectionCallback: @escaping ((String) -> Void)
    ) {
        self.sites = sites
        self._pinnedDomains = pinnedDomains
        self._isEditing = isEditing
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
        VStack {
            List {
                pinnedSection
                unPinnedSection
            }
            .listStyle(.grouped)
            addSiteButtonVStack
        }
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
                ForEach(
                    pinnedSites,
                    id: \.domain) { site in
                        siteButton(
                            site: site
                        )
                    }
            } header: {
                sectionHeader(
                    title: "Pinned sites"
                )
                .listRowInsets(EdgeInsets(
                    top: Length.Padding.medium,
                    leading: Length.Padding.double,
                    bottom: 0,
                    trailing: Length.Padding.double)
                )

            }
        }
    }

    @ViewBuilder
    private var unPinnedSection: some View {
        let unPinnedSites = BlogListReducer.unPinnedSites(
            allSites: sites,
            pinnedDomains: pinnedDomains
        )
        if !unPinnedSites.isEmpty {
            Section {
                ForEach(
                    unPinnedSites,
                    id: \.domain) { site in
                        siteButton(
                            site: site
                        )
                    }
            } header: {
                sectionHeader(
                    title: "All sites"
                )
            }
        }
    }

    private func siteButton(site: Site) -> some View {
        Button {
            if isEditing {
                withAnimation {
                    pinnedDomains = pinnedDomains.symmetricDifference([site.domain])
                }
            } else {
                selectionCallback(site.domain)
            }
        } label: {
            siteHStack(site: site)
        }
        .buttonStyle(BlogListButtonStyle())
        .listRowSeparator(.hidden)
        .listRowInsets(
            .init(
                top: Length.Padding.single,
                leading: 0,
                bottom: Length.Padding.single,
                trailing: 0
            )
        )
        .listRowBackground(Color.DS.Background.primary)
    }

    private func siteHStack(site: Site) -> some View {
        HStack(spacing: 0) {
            AvatarsView(style: .single(site.imageURL))
                .padding(.leading, Length.Padding.double)
                .padding(.trailing, Length.Padding.split)

            textsVStack(title: site.title, domain: site.domain)

            Spacer()

            if isEditing {
                pinIcon(
                    domain: site.domain
                )
                .padding(.trailing, Length.Padding.double)
            }
        }
        .padding(.vertical, Length.Padding.half)
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
                .padding(.top, Length.Padding.half)
        }
    }

    private func pinIcon(domain: String) -> some View {
        if pinnedDomains.contains(domain) {
            Image(systemName: "pin.fill")
                .imageScale(.small)
                .foregroundStyle(Color.DS.Background.brand(isJetpack: true))
        } else {
            Image(systemName: "pin")
                .imageScale(.small)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }

    private var addSiteButtonVStack: some View {
        VStack(spacing: Length.Padding.medium) {
            Divider()
                .background(Color.DS.Foreground.secondary)
            DSButton(title: "Add a site", style: .init(emphasis: .primary, size: .large)) {
                // Add a site
            }
            .padding(.horizontal, Length.Padding.medium)
        }
        .background(Color.DS.Background.primary)
    }
}

private struct BlogListButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.DS.Background.secondary : Color.DS.Background.primary)
    }
}
