import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressCore
import SafariServices

struct PluginListItemView: View {

    @ScaledMetric(relativeTo: .body) var descriptionFontSize: CGFloat = 14
    @State private var showingSafariView = false

    let plugin: InstalledPlugin
    let viewModel: InstalledPluginsListViewModel

    // Add this computed property to avoid direct state access in the view body
    private var isUpdating: Bool {
        viewModel.updating.contains(plugin.slug)
    }

    var body: some View {
        HStack(alignment: .top) {
            PluginIconView(slug: plugin.possibleWpOrgDirectorySlug, service: viewModel.service)

            VStack(alignment: .leading, spacing: 0) {
                Text(plugin.name)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.primary)

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

            Spacer()
        }
        .overlay(alignment: .bottomTrailing) {
            Menu {
                Section {
                    if plugin.isActive {
                        Button("Deactivate", systemImage: "bolt.slash") {
                            Task {
                                await viewModel.toggle(slug: plugin.slug)
                            }
                        }
                    } else {
                        Button("Activate", systemImage: "bolt") {
                            Task {
                                await viewModel.toggle(slug: plugin.slug)
                            }
                        }
                        Button("Delete", systemImage: "trash") {
                            Task {
                                await viewModel.uninstall(slug: plugin.slug)
                            }
                        }
                    }
                }
                .disabled(isUpdating)

                if let url = wpOrgURL {
                    Section {
                        Button {
                            showingSafariView = true
                        } label: {
                            Label("View on WordPress.org", systemImage: "safari")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(4)
                    .frame(width: 44, height: 44, alignment: .bottomTrailing)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showingSafariView) {
            if let url = wpOrgURL {
                SafariView(url: url)
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

    private var wpOrgURL: URL? {
        guard let slug = plugin.possibleWpOrgDirectorySlug else { return nil }
        return URL(string: "https://wordpress.org/plugins/\(slug.slug)/")
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

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
    }
}
