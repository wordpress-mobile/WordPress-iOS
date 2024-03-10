import Foundation
import WordPressKit

extension RemotePostCreateParameters {
    /// Initializes the parameters required to create the given post.
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
            tags = makeTags(from: post.tags ?? "")
            categoryIDs = (post.categories ?? []).compactMap {
                $0.categoryID?.intValue
            }
        default:
            break
        }
    }
}

private func makeTags(from tags: String) -> [String] {
    tags
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

extension RemotePostUpdateParameters {
    /// Returns a diff between the original and the latest revision with the
    /// changes applied on top.
    static func changes(from original: AbstractPost, to latest: AbstractPost, with changes: RemotePostUpdateParameters?) -> RemotePostUpdateParameters {
        let parametersOriginal = RemotePostCreateParameters(post: original)
        var parametersLatest = RemotePostCreateParameters(post: latest)
        if let changes {
            parametersLatest.apply(changes)
        }
        return parametersLatest.changes(from: parametersOriginal)
    }
}

enum RemotePostUpdateError {
    /// 409 (Conflict)
    case conflict
    /// 404 (Not Found)
    case notFound

    init?(_ error: Error) {
        let userInfo = (error as NSError).userInfo
        guard let code = userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String else {
            return nil
        }
        switch code {
        case "old-revision": self = .conflict
        case "unknown_post": self = .notFound
        default: return nil
        }
    }
}
