import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

struct PluginIconView: View {
    private static let iconSize: CGFloat = 44

    let slug: PluginWpOrgDirectorySlug?
    let plugin: PluginInformation?
    @State var iconURL: URL?

    var service: PluginServiceProtocol

    init(slug: PluginWpOrgDirectorySlug?, service: PluginServiceProtocol) {
        self.slug = slug
        self.plugin = nil
        self.service = service
    }

    init(plugin: PluginInformation, service: PluginServiceProtocol) {
        self.slug = PluginWpOrgDirectorySlug(slug: plugin.slug)
        self.plugin = plugin
        self.service = service
    }

    var body: some View {
        CachedAsyncImage(url: iconURL) { image in
            image.resizable()
        } placeholder: {
            Image(systemName: "puzzlepiece.extension")
        }
        .frame(width: Self.iconSize, height: Self.iconSize)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .task(id: slug?.slug) {
            guard let slug else { return }
            iconURL = await service.resolveIconURL(of: slug, plugin: plugin)
        }
    }
}
