import DesignSystem
import SwiftUI
import WordPressShared

struct BlogListSiteView: View {
    let site: BlogListSiteViewModel

    var body: some View {
        HStack(alignment: .center, spacing: .DS.Padding.double) {
            SiteIconView(viewModel: site.icon)
                .frame(width: 40, height: 40)

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
}

final class BlogListSiteViewModel: Identifiable {
    var id: NSManagedObjectID { blog.objectID }
    let title: String
    let domain: String
    let icon: SiteIconViewModel
    let searchTags: String

    var siteURL: URL? {
        blog.url.flatMap(URL.init)
    }

    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
        self.title = blog.title ?? "–"
        self.domain = blog.displayURL as String? ?? ""
        self.icon = SiteIconViewModel(blog: blog)

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
