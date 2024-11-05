import SwiftUI
import WordPressKit

struct ReaderFeedCell: View {
    let feed: ReaderFeed

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SiteIconView(viewModel: .init(feed: feed))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(feed.title.stringByDecodingXMLCharacters())
                    .font(.body)
                    .lineLimit(1)

                Text(feed.urlForDisplay)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

extension SiteIconViewModel {
    init(feed: ReaderFeed, size: Size = .regular) {
        self.size = size
        if let iconURL = feed.blavatarURL {
            self.imageURL = SiteIconViewModel.optimizedURL(for: iconURL.absoluteString, imageSize: size.size)
        }
    }
}

private extension ReaderFeed {
    /// Strips the protocol and query from the URL.
    ///
    var urlForDisplay: String {
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
