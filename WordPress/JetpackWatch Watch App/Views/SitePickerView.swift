import SwiftUI

struct SitePickerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if env.siteCatalog.sites.isEmpty {
                ContentUnavailableView(
                    "No sites",
                    systemImage: "globe.badge.chevron.backward",
                    description: Text("Add a site in Jetpack on your iPhone.")
                )
            } else {
                List(env.siteCatalog.sites) { site in
                    Button { select(site) } label: {
                        HStack {
                            Text(site.name)
                            Spacer()
                            if env.siteCatalog.defaultSiteID == site.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Site")
    }

    private func select(_ site: Site) {
        env.siteCatalog.setDefaultSiteID(site.id)
        let bridge = env.phoneBridge
        Task { await bridge.setDefaultSiteID(site.id) }
        dismiss()
    }
}
