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
        List {
            pinnedSection
            unPinnedSection
        }
        .listStyle(.grouped)
        .background(Color.DS.Background.primary)
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
                        siteHStack(
                            site: site
                        )
                    }
            } header: {
                sectionHeader(
                    title: "Pinned sites"
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
                        siteHStack(
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

    private func siteHStack(site: Site) -> some View {
        Button {
            if isEditing {
                withAnimation {
                    pinnedDomains = pinnedDomains.symmetricDifference([site.domain])
                }
            } else {
                selectionCallback(site.domain)
            }
        } label: {
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
}

private struct BlogListButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.DS.Background.secondary : Color.DS.Background.primary)
    }
}
