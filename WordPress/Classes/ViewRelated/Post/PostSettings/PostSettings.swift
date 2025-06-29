import Foundation
import WordPressData
import WordPressKit
import WordPressShared

/// A plain data structure representing the subset of post/page settings that can be edited in PostSettingsView.
/// Used for change tracking and to separate UI state from Core Data objects.
struct PostSettings: Hashable {
    struct Author: Hashable {
        let id: Int
        let displayName: String
        let avatarURL: URL?
    }

    var excerpt: String
    var slug: String
    var status: BasePost.Status
    var publishDate: Date?
    var password: String?
    var author: Author?
    var categoryIDs: Set<Int> = []
    var tags: String = ""
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

        if let authorID = post.authorID?.intValue, authorID > 0 {
            author = Author(
                id: authorID,
                displayName: post.author ?? "–",
                avatarURL: post.authorAvatarURL.flatMap(URL.init)
            )
        }

        featuredImageID = post.featuredImage?.mediaID?.intValue

        switch post {
        case let post as Post:
            postFormat = post.postFormat
            isStickyPost = post.isStickyPost
            tags = post.tags ?? ""
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
        if post.mt_excerpt != excerpt {
            post.mt_excerpt = excerpt
        }
        if post.wp_slug != slug {
            post.wp_slug = slug
        }
        if post.status != status {
            post.status = status
        }
        if post.dateCreated != publishDate {
            post.dateCreated = publishDate
        }
        if post.password != password {
            post.password = password
        }
        if let author, post.authorID?.intValue != author.id {
            post.authorID = NSNumber(value: author.id)
            post.author = author.displayName
            post.authorAvatarURL = author.avatarURL?.absoluteString
        }
        // Apply featured image changes
        if let featuredImageID {
            // Only update if changed
            if post.featuredImage?.mediaID?.intValue != featuredImageID {
                post.featuredImage = Media.existingOrStubMediaWith(mediaID: NSNumber(value: featuredImageID), inBlog: post.blog)
            }
        } else {
            post.featuredImage = nil
        }

        switch post {
        case let post as Post:
            // Update tags
            if post.tags != tags {
                post.tags = tags
            }

            // Update categories
            let currentCategoryIDs = Set((post.categories ?? []).compactMap { $0.categoryID?.intValue })
            if currentCategoryIDs != categoryIDs {
                // Find category objects for the IDs
                let allCategories = post.blog.categories ?? []
                let selectedCategories = allCategories.filter { category in
                    if let categoryID = category.categoryID?.intValue {
                        return categoryIDs.contains(categoryID)
                    }
                    return false
                }
                post.categories = Set(selectedCategories)
            }

            // Update post format
            if post.postFormat != postFormat {
                post.postFormat = postFormat
            }

            // Update sticky post setting
            if post.isStickyPost != isStickyPost {
                post.isStickyPost = isStickyPost
            }
        case let page as Page:
            if page.parentID?.intValue != parentPageID {
                page.parentID = parentPageID.map { NSNumber(value: $0) }
            }
        default:
            wpAssertionFailure("unsupported post type", userInfo: ["post_type": String(describing: type(of: post))])
        }
    }

    // MARK: - Diff Generation

    /// Creates RemotePostUpdateParameters representing the changes from the original settings.
    /// Uses the existing RemotePostUpdateParameters.changes infrastructure by creating
    /// a temporary post copy, applying the new settings, and computing the diff.
    func makeUpdateParameters(from original: AbstractPost) -> RemotePostUpdateParameters {
        guard let context = original.managedObjectContext else {
            wpAssertionFailure("post must have a managed object context")
            return RemotePostUpdateParameters()
        }
        // Create a temporary copy of the post to apply the new settings
        let temporaryPost = original.createRevision()
        self.apply(to: temporaryPost)
        let parameters = RemotePostUpdateParameters.changes(from: original, to: temporaryPost)
        context.delete(temporaryPost)
        return parameters
    }
}

extension PostSettings {
    var isPendingReview: Bool {
        get { status == .pending }
        set { status = newValue ? .pending : .draft }
    }

    mutating func updateAuthor(with authorItem: PostAuthorPickerViewModel.AuthorItem) {
        author = PostSettings.Author(
            id: authorItem.id.intValue,
            displayName: authorItem.displayName,
            avatarURL: authorItem.avatarURL
        )
    }

    func getCategoryNames(for post: AbstractPost) -> [String] {
        guard let post = post as? Post else {
            return []
        }
        var categories: [Int: String] = [:]
        for category in post.blog.categories ?? [] {
            if let id = category.categoryID?.intValue, let name = category.categoryName {
                categories[id] = name
            }
        }
        return categoryIDs.compactMap { categories[$0] }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { $0.stringByDecodingXMLCharacters() }
    }
}
