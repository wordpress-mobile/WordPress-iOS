import DesignSystem
import SwiftUI

struct BlogListSiteView: View {
    let site: BlogListSiteViewModel

    var body: some View {
        HStack(alignment: .center, spacing: .DS.Padding.double) {
            CachedAsyncImage(url: site.imageURL) { image in
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
}

final class BlogListSiteViewModel: Identifiable {
    let id: NSNumber
    let title: String
    let domain: String
    let imageURL: URL?
    let searchTags: String

    init(blog: Blog) {
        self.id = blog.dotComID ?? 0
        self.title = blog.title ?? "–"
        self.domain = blog.displayURL as String? ?? ""
        self.imageURL = blog.hasIcon ? blog.icon.flatMap(URL.init) : nil

        NSLog(blog.icon ?? "")

        // By adding displayURL _after_ the title, it loweres its weight in search
        self.searchTags = "\(title) \(domain)"
    }
}
