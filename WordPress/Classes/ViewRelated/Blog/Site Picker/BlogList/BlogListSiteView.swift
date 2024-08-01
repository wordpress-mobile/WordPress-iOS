import DesignSystem
import SwiftUI

struct BlogListSiteView: View {
    let site: BlogListSiteViewModel

    var body: some View {
        HStack(alignment: .center, spacing: .DS.Padding.double) {
            siteIconView
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading) {
                Text(site.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.DS.Foreground.primary)
                    .lineLimit(2)

                Text(site.domain)
                    .font(.footnote)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var siteIconView: some View {
        if let imageURL = site.imageURL {
            CachedAsyncImage(url: imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.DS.Background.secondary
                    .overlay {
                        Image.DS.icon(named: .vector)
                            .resizable()
                            .frame(width: 18, height: 18)
                            .tint(.DS.Foreground.tertiary)
                    }
            }
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Text(site.firstLetter?.uppercased() ?? "@")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
        }
    }
}

final class BlogListSiteViewModel: Identifiable {
    var id: NSManagedObjectID { blog.objectID }
    let title: String
    let domain: String
    let imageURL: URL?
    let searchTags: String

    var firstLetter: Character? {
        title.first ?? domain.first
    }

    var siteURL: URL? {
        blog.url.flatMap(URL.init)
    }

    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
        self.title = blog.title ?? "–"
        self.domain = blog.displayURL as String? ?? ""
        self.imageURL = blog.hasIcon ? blog.icon.flatMap(URL.init) : nil

        // By adding displayURL _after_ the title, it loweres its weight in search
        self.searchTags = "\(title) \(domain)"
    }

    func buttonViewTapped() {
        guard let siteURL else {
            return wpAssertionFailure("missing-url")
        }
        WPAnalytics.track(.siteListViewTapped)
        UIApplication.shared.open(siteURL)
    }

    func buttonCopyLinkTapped() {
        UIPasteboard.general.string = siteURL?.absoluteString
        WPAnalytics.track(.siteListCopyLinktapped)
    }
}
