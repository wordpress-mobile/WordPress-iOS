import Foundation
import WordPressKit

extension RemotePostCreateParameters {
    init(post: AbstractPost) {
        self.init(status: (post.status ?? .draft).rawValue)
        date = post.dateCreated
        authorID = post.authorID?.intValue
        title = post.postTitle
        content = post.content
        password = post.password
        excerpt = post.mt_excerpt
        slug = post.wp_slug
        featuredImageID = post.featuredImage?.mediaID?.intValue
        switch post {
        case let page as Page:
            parentPageID = page.parentID?.intValue
        case let post as Post:
            format = post.postFormat
            isSticky = post.isStickyPost
            tags = (post.tags ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            categoryIDs = (post.categories ?? []).compactMap {
                $0.categoryID?.intValue
            }
        default:
            break
        }
    }
}
