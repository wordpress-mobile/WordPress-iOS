import SwiftUI
import WordPressShared

struct BlogListSiteView: View {
    let site: BlogListSiteViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SiteIconView(viewModel: site.icon)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(site.title)
                        .font(.callout.weight(.medium))

                    if let badge = site.badge {
                        makeBadge(with: badge)
                    }
                }
                Text(site.domain)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
    }

    func makeBadge(with viewModel: BlogListSiteViewModel.Badge) -> some View {
        Text(viewModel.title.uppercased())
            .lineLimit(1)
            .font(.caption2.weight(.semibold))
            .padding(EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
            .background(viewModel.color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(height: 10) // Make sure it doesn't affect the layout and spacing
    }
}

final class BlogListSiteViewModel: Identifiable {
    var id: TaggedManagedObjectID<Blog> { TaggedManagedObjectID(blog) }
    let title: String
    let domain: String
    let icon: SiteIconViewModel
    let searchTags: String
    var badge: Badge?

    var siteURL: URL? {
        blog.url.flatMap(URL.init)
    }

    struct Badge {
        let title: String
        let color: Color
    }

    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
        self.title = blog.title ?? "–"
        self.domain = blog.displayURL as String? ?? ""
        self.icon = SiteIconViewModel(blog: blog)

        // By adding displayURL _after_ the title, it loweres its weight in search
        self.searchTags = "\(title) \(domain)"

        if (blog.getOption(name: "is_wpcom_staging_site") as Bool?) == true {
            badge = Badge(title: Strings.staging, color: Color.yellow.opacity(0.33))
        }
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

private enum Strings {
    static let staging = NSLocalizedString("blogList.siteBadge.staging", value: "Staging", comment: "Badge title in site list")
}
