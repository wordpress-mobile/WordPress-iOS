import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressCore
import WordPressShared
import SafariServices

struct PluginListItemView: View {

    @State private var isShowingSafariView = false

    let plugin: InstalledPlugin
    let viewModel: InstalledPluginsListViewModel

    // Add this computed property to avoid direct state access in the view body
    private var isUpdating: Bool {
        viewModel.updating.contains(plugin.slug)
    }

    var body: some View {
        HStack(alignment: .top) {
            PluginIconView(slug: plugin.possibleWpOrgDirectorySlug, service: viewModel.service)

            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name.makePlainText())
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(plugin.shortDescription.makePlainText())
                    .lineLimit(2)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(Strings.version(plugin.version))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .sheet(isPresented: $isShowingSafariView) {
            if let url = plugin.possibleWpOrgDirectoryURL {
                SafariView(url: url)
            }
        }
    }

    private enum Strings {
        static func author(_ author: String) -> String {
            let format = NSLocalizedString("sitePluginsList.item.author", value: "By %@", comment: "The plugin author displayed in the plugins list. The first argument is plugin author name")
            return String(format: format, author)
        }

        static func version(_ version: String) -> String {
            let format = NSLocalizedString("sitePluginsList.item.author", value: "Version: %@", comment: "The plugin version displayed in the plugins list. The first argument is plugin version")
            return String(format: format, version)
        }

        static let noDescriptionAvailable: String = NSLocalizedString("sitePluginsList.item.noDescriptionAvailable", value: "The plugin author did not provide a description for this plugin.", comment: "The message displayed when a plugin has no description")

        static let activate: String = NSLocalizedString("sitePluginsList.itemAction.activate", value: "Activate", comment: "Button to activate a plugin")
        static let deactivate: String = NSLocalizedString("sitePluginsList.itemAction.deactivate", value: "Deactivate", comment: "Button to deactivate a plugin")
        static let delete: String = NSLocalizedString("sitePluginsList.itemAction.delete", value: "Delete", comment: "Button to delete a plugin")
        static let viewOnWordPressOrg: String = NSLocalizedString("sitePluginsList.itemAction.viewOnWordPressOrg", value: "View on WordPress.org", comment: "Button to view the plugin on WordPress.org website")
    }
}
