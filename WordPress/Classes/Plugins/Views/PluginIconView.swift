import Foundation
import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressCore

struct PluginIconView: View {
    private static let iconSize: CGFloat = 44

    let slug: PluginWpOrgDirectorySlug?
    @State var iconURL: URL?

    var service: PluginServiceProtocol

    var body: some View {
        CachedAsyncImage(url: iconURL) { image in
            image.resizable()
        } placeholder: {
            Image("site-menu-plugins")
                .resizable()
        }
        .frame(width: Self.iconSize, height: Self.iconSize)
        .padding(.all, 4)
        .task(id: slug?.slug) {
            guard let slug else { return }
            iconURL = await service.resolveIconURL(of: slug)
        }
    }
}
