import SwiftUI
import AsyncImageKit
import WordPressUI

struct ReaderSiteIconView: View, Hashable {
    let site: ReaderSiteTopic
    var size: SiteIconViewModel.Size = .small

    var body: some View {
        _ReaderSiteIconView(viewModel: .init(site: site, size: size))
            .id(self) // important to ensure @StateObject is re-created if needed
            .frame(width: size.width, height: size.width)
    }
}

private struct _ReaderSiteIconView: View {
    @StateObject var viewModel: ReaderSiteIconViewModel

    var body: some View {
        SiteIconView(viewModel: viewModel.icon)
            .task { await viewModel.refresh() }
    }
}

@MainActor
final class ReaderSiteIconViewModel: ObservableObject {
    @Published private(set) var icon: SiteIconViewModel

    let site: ReaderSiteTopic
    let size: SiteIconViewModel.Size

    init(site: ReaderSiteTopic, size: SiteIconViewModel.Size) {
        self.site = site
        self.size = size
        self.icon = SiteIconViewModel(readerSiteTopic: site, size: size)
    }

    func refresh() async {
        if site.isExternal, icon.imageURL == nil, let siteURL = URL(string: site.siteURL) {
            if let faviconURL = FaviconService.shared.cachedFavicon(forURL: siteURL) {
                icon.imageURL = faviconURL
            } else {
                icon.imageURL = try? await FaviconService.shared.favicon(forURL: siteURL)
            }
        }
    }
}
