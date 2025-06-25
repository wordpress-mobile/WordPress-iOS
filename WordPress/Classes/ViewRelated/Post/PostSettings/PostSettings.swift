import Foundation
import WordPressData
import WordPressKit
import WordPressShared

/// A plain data structure representing the subset of post/page settings that can be edited in PostSettingsView.
/// Used for change tracking and to separate UI state from Core Data objects.
struct PostSettings: Hashable {
    var excerpt: String
    var slug: String
    var status: BasePost.Status
    var publishDate: Date?
    var password: String?
    var authorID: Int?
    var categoryIDs: Set<Int> = []
    var tags: [String] = []
    var featuredImageID: Int?

    // MARK: - Post-specific
    var postFormat: String?
    var isStickyPost = false

    // MARK: - Page-specific
    var parentPageID: Int?

    // MARK: - Initialization

    /// Creates PostSettings from an AbstractPost instance.
    init(from post: AbstractPost) {
        excerpt = post.mt_excerpt ?? ""
        slug = post.wp_slug ?? ""
        status = post.status ?? .draft
        publishDate = post.dateCreated
        password = post.password
        authorID = post.authorID?.intValue
        featuredImageID = post.featuredImage?.mediaID?.intValue

        switch post {
        case let post as Post:
            postFormat = post.postFormat
            isStickyPost = post.isStickyPost
            tags = AbstractPost.makeTags(from: post.tags ?? "")
            categoryIDs = Set((post.categories ?? []).compactMap {
                $0.categoryID?.intValue
            })
        case let page as Page:
            parentPageID = page.parentID?.intValue
        default:
            wpAssertionFailure("unsupported post type", userInfo: ["post_type": String(describing: type(of: post))])
        }
    }

    // MARK: - Applying Changes

    /// Applies the settings to an AbstractPost instance.
    /// Only updates properties that have actually changed.
    func apply(to post: AbstractPost) {
        if post.wp_slug != slug {
            post.wp_slug = slug
        }
        // TODO: implement it for the remaining fields
    }

    // MARK: - Diff Generation

    /// Creates RemotePostUpdateParameters representing the changes from the original settings.
    func makeUpdateParameters(from original: PostSettings) -> RemotePostUpdateParameters {
        var parameters = RemotePostUpdateParameters()
        if slug != original.slug {
            parameters.slug = slug
        }
        // TODO: implement it for the remaining field
        return parameters
    }
}
