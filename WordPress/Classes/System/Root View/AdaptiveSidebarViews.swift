import SwiftUI
import WordPressData
import WordPressUI

struct AdaptiveSidebarSitesView: View {
    @ObservedObject var model: SidebarViewModel
    @ObservedObject var sites: BlogListViewModel
    let onSelect: (Blog) -> Void
    let onAllSites: (CGRect) -> Void
    let onAddSite: (AddSiteMenuViewModel.Selection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("sidebar.mySites", value: "My Sites", comment: "Sidebar sites section"))
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            ForEach(sites.topSites) { site in
                Button {
                    if let blog = sites.didSelectSite(withID: site.id.objectID) { onSelect(blog) }
                } label: {
                    HStack {
                        BlogListSiteView(site: site, style: .sidebar)
                        if model.selection == .blog(site.id) {
                            Image(systemName: "checkmark").foregroundStyle(AppColor.tint)
                        }
                    }
                    .padding(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sidebar_site_\(site.domain)")
                .accessibilityAddTraits(model.selection == .blog(site.id) ? .isSelected : [])
            }
            GeometryReader { proxy in
                Button {
                    onAllSites(proxy.frame(in: .global))
                } label: {
                    Label(
                        NSLocalizedString(
                            "sidebar.allSites",
                            value: "All Sites",
                            comment: "Sidebar button title on iPad"
                        ),
                        systemImage: "rectangle.stack"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
                .accessibilityIdentifier("sidebar_all_sites")
            }
            .frame(height: 44)
            Menu {
                let menu = AddSiteMenuViewModel(onSelection: onAddSite)
                ForEach(menu.actions) { action in
                    Button(action.title, action: action.handler)
                }
            } label: {
                Label(
                    NSLocalizedString("sidebar.addSite", value: "Add Site", comment: "Sidebar button title on iPad"),
                    systemImage: "plus.circle"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            .accessibilityIdentifier("sidebar_add_site")
        }
        .tint(AppColor.primary)
        .padding(.vertical, 8)
    }
}

struct AdaptiveSidebarAccountView: View {
    @ObservedObject var model: SidebarViewModel
    let onSelect: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        HStack {
            if let account = model.account {
                Button(action: onSelect) { SidebarProfileView(account: account) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sidebar_me")
            } else {
                if AppConfiguration.isJetpack {
                    Button(action: onSignIn) {
                        Label(
                            NSLocalizedString("Sign In", comment: "Sign in button"),
                            systemImage: "person.crop.circle"
                        )
                    }
                }
                Spacer()
                Button(action: onSelect) { Image(systemName: "gearshape") }
                    .accessibilityLabel(NSLocalizedString("Me", comment: "Account and app settings"))
                    .accessibilityIdentifier("sidebar_me")
            }
        }
        .padding()
        .background(.bar)
        .tint(AppColor.primary)
    }
}
