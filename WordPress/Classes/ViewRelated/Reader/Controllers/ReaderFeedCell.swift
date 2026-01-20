import SwiftUI
import WordPressUI
import WordPressKit

struct ReaderFeedCell: View {
    let feed: ReaderFeed
    @State private var faviconURL: URL?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SiteIconView(viewModel: .init(feed: feed, faviconURL: faviconURL))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .task {
            await loadFaviconIfNeeded()
        }
    }

    private func loadFaviconIfNeeded() async {
        guard feed.iconURL == nil, let url = feed.url else {
            return
        }

        if let cachedFavicon = FaviconService.shared.cachedFavicon(forURL: url) {
            faviconURL = cachedFavicon
        } else {
            faviconURL = try? await FaviconService.shared.favicon(forURL: url)
        }
    }

    var title: String {
        if let title = feed.title?.stringByDecodingXMLCharacters(), !title.isEmpty {
            return title.replacing(/\s+/) { _ in " " }
        }
        return feed.urlForDisplay ?? "–"
    }

    var subtitle: String? {
        if let description = feed.description, !description.isEmpty {
            return description.stringByDecodingXMLCharacters()
        }
        return feed.urlForDisplay
    }
}

extension SiteIconViewModel {
    init(feed: ReaderFeed, faviconURL: URL? = nil, size: Size = .regular) {
        self.init(size: size)
        if let iconURL = feed.iconURL {
            self.imageURL = SiteIconViewModel.optimizedURL(for: iconURL.absoluteString, imageSize: size.size)
        } else if let faviconURL {
            self.imageURL = faviconURL
        }
    }
}

private extension ReaderFeed {
    /// Strips the protocol and query from the URL.
    ///
    var urlForDisplay: String? {
        guard let url else {
            return nil
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host else {
            return url.absoluteString
        }

        let path = components.path
        if path.isEmpty && path != "/" {
            return host + path
        } else {
            return host
        }
    }
}
