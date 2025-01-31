import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressCore

struct PluginListItemView: View {

    @ScaledMetric(relativeTo: .body) var descriptionFontSize: CGFloat = 14

    private var slug: PluginWpOrgDirectorySlug?
    private var iconURL: URL?
    private var name: String
    private var version: String
    private var author: String
    private var shortDescription: String
    private var service: PluginServiceProtocol

    init(plugin: InstalledPlugin, service: PluginServiceProtocol) {
        self.slug = plugin.possibleWpOrgDirectorySlug
        self.iconURL = plugin.iconURL
        self.name = plugin.name
        self.version = plugin.version
        self.author = plugin.author
        self.shortDescription = plugin.shortDescription
        self.service = service
    }

    var body: some View {
        HStack(alignment: .top) {
            PluginIconView(slug: slug, service: service)

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !author.isEmpty {
                    Text(Strings.author(author))
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    if shortDescription.isEmpty {
                        Text(Strings.noDescriptionAvailable)
                            .font(.system(size: descriptionFontSize).italic())
                    } else if let html = renderedDescription() {
                        Text(html)
                    } else {
                        Text(shortDescription)
                            .font(.system(size: descriptionFontSize))
                    }
                }
                .padding(.vertical, 4)

                Text(Strings.version(version))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    func renderedDescription() -> AttributedString? {
        guard var data = shortDescription.data(using: .utf8) else {
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
