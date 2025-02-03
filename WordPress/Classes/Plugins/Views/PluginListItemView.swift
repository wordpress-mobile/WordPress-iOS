import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressCore

struct PluginListItemView: View {

    @ScaledMetric(relativeTo: .body) var descriptionFontSize: CGFloat = 14

    var plugin: InstalledPlugin
    var service: PluginServiceProtocol

    var body: some View {
        HStack(alignment: .top) {
            PluginIconView(slug: plugin.possibleWpOrgDirectorySlug, service: service)

            VStack(alignment: .leading, spacing: 0) {
                Text(plugin.name)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !plugin.author.isEmpty {
                    Text(Strings.author(plugin.author))
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    if plugin.shortDescription.isEmpty {
                        Text(Strings.noDescriptionAvailable)
                            .font(.system(size: descriptionFontSize).italic())
                    } else if let html = renderedDescription() {
                        Text(html)
                    } else {
                        Text(plugin.shortDescription)
                            .font(.system(size: descriptionFontSize))
                    }
                }
                .lineLimit(2)
                .padding(.vertical, 4)

                Text(Strings.version(plugin.version))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // TODO: Use `WebCommentContentRenderer` instead.
    // There are potential crash and performance issues in NSAttributedString's HTML support.
    // http://www.openradar.me/20978452
    func renderedDescription() -> AttributedString? {
        guard var data = plugin.shortDescription.data(using: .utf8) else {
            return nil
        }

        // We want to use the system font, instead of the default "Times New Roman" font in the rendered HTML.
        // Using `.defaultAttributes: [.font: systemFont(...)]` in the `NSAttributedString` initialiser below doesn't
        // work. Using a CSS style here as a workaround.
        data.append(contentsOf: "<style> body { font-family: -apple-system; font-size: \(descriptionFontSize)px; } </style>".data(using: .utf8)!)

        do {
            let string = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                    .sourceTextScaling: NSTextScalingType.iOS,
                ],
                documentAttributes: nil
            )
            return try AttributedString(string, including: \.uiKit)
        } catch {
            DDLogError("Failed to parse HTML: \(error)")
            return nil
        }
    }

    private enum Strings {
        static func author(_ author: String) -> String {
            let format = NSLocalizedString("site.plugins.list.item.author", value: "By %@", comment: "The plugin author displayed in the plugins list. The first argument is plugin author name")
            return String(format: format, author)
        }

        static func version(_ version: String) -> String {
            let format = NSLocalizedString("site.plugins.list.item.author", value: "Version: %@", comment: "The plugin version displayed in the plugins list. The first argument is plugin version")
            return String(format: format, version)
        }

        static let noDescriptionAvailable: String = NSLocalizedString("site.plugins.list.item.noDescriptionAvailable", value: "The plugin author did not provide a description for this plugin.", comment: "The message displayed when a plugin has no description")
    }
}
