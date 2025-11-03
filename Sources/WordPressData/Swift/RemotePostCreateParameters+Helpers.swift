import Foundation
import WordPressKit
import WordPressShared

extension RemotePostCreateParameters {
    /// Initializes the parameters required to create the given post.
    public init(post: AbstractPost) {
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
        otherTerms = post.parseOtherTerms()
        switch post {
        case let page as Page:
            parentPageID = page.parentID?.intValue
        case let post as Post:
            format = post.postFormat
            isSticky = post.isStickyPost
            tags = AbstractPost.makeTags(from: post.tags ?? "")
            categoryIDs = (post.categories ?? []).compactMap {
                $0.categoryID?.intValue
            }
            metadata = Set(Self.generateRemoteMetadata(for: post).compactMap { dictionary -> RemotePostMetadataItem? in
                return PostHelper.mapDictionaryToMetadataItems(dictionary)
            })
            discussion = RemotePostDiscussionSettings(
                allowComments: post.allowComments,
                allowPings: post.allowPings
            )
        default:
            break
        }
    }
}

private extension RemotePostCreateParameters {
    /// Generates remote metadata for the given post.
    ///
    /// - note: It includes _only_ the keys known to the app and that you as a
    /// user can change from the app.
    static func generateRemoteMetadata(for post: Post) -> [[String: Any]] {
        // Start with existing metadata from PostHelper
        var output = PostHelper.remoteMetadata(for: post) as? [[String: Any]] ?? []
        // Add metadata mananged using `PostMetadata`
        output += PostMetadata.entries(in: PostMetadataContainer(post))
        return output
    }
}
