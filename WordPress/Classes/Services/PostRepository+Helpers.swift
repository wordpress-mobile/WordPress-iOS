import Foundation
import WordPressKit
import WordPressShared

extension RemotePostCreateParameters {
    /// Initializes the parameters required to create the given post.
    init(post: AbstractPost) {
        self.init(
            type: post is Post ? "post" : "page",
            status: (post.status ?? .draft).rawValue
        )
        date = post.dateCreated
        // - warning: the currnet Core Data model defaults to `0`
        if let authorID = post.authorID?.intValue, authorID > 0 {
            self.authorID = authorID
        }
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
            metadata = Set(PostHelper.remoteMetadata(for: post).compactMap { value -> RemotePostMetadataItem? in
                guard let dictionary = value as? [String: Any] else {
                    wpAssertionFailure("Unexpected value", userInfo: [
                        "value": value
                    ])
                    return nil
                }
                return PostHelper.mapDictionaryToMetadataItems(dictionary)
            })
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
    var isEmpty: Bool {
        self == RemotePostUpdateParameters()
    }

    /// Returns a diff between the original and the latest revision with the
    /// changes applied on top.
    static func changes(from original: AbstractPost, to latest: AbstractPost, with changes: RemotePostUpdateParameters? = nil) -> RemotePostUpdateParameters {
        guard original !== latest else {
            return changes ?? RemotePostUpdateParameters()
        }
        let parametersOriginal = RemotePostCreateParameters(post: original)
        var parametersLatest = RemotePostCreateParameters(post: latest)
        if let changes {
            parametersLatest.apply(changes)
        }
        return parametersLatest.changes(from: parametersOriginal)
    }
}
