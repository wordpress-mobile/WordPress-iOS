import Foundation
import WordPressData
import WordPressKit

/// A plain data structure representing the subset of post/page settings that can be edited in PostSettingsView.
/// Used for change tracking and to separate UI state from Core Data objects.
struct PostSettings: Hashable {
    // MARK: - More Options
    var excerpt: String
    var slug: String

    // MARK: - Publishing
    var status: String
    var publishDate: Date?
    var password: String?

    // MARK: - Author
    var authorID: Int?

    // MARK: - Taxonomies
    var categoryIDs: Set<Int>
    var tags: String

    // MARK: - Media
    var featuredImageID: Int?

    // MARK: - Post-specific
    var postFormat: String?
    var isStickyPost: Bool

    // MARK: - Page-specific
    var parentPageID: Int?

    // MARK: - Social
    var publicizeMessage: String?
    var disabledPublicizeConnectionIDs: Set<NSNumber>

    // MARK: - Initialization

    /// Creates PostSettings from an AbstractPost instance.
    init(from post: AbstractPost) {
        self.excerpt = post.mt_excerpt ?? ""
        self.slug = post.wp_slug ?? ""

        self.status = post.status ?? PostStatusDraft
        self.publishDate = post.dateCreated
        self.password = post.password

        self.authorID = post.authorID?.intValue

        // Extract category IDs
        if let post = post as? Post {
            self.categoryIDs = Set((post.categories ?? []).compactMap { $0.categoryID?.intValue })
            self.tags = post.tags ?? ""
            self.postFormat = post.postFormat
            self.isStickyPost = post.isStickyPost
        } else {
            self.categoryIDs = []
            self.tags = ""
            self.postFormat = nil
            self.isStickyPost = false
        }

        self.featuredImageID = post.featuredImage?.mediaID?.intValue

        if let page = post as? Page {
            self.parentPageID = page.parentID?.intValue
        } else {
            self.parentPageID = nil
        }

        // Social settings
        if let post = post as? Post {
            self.publicizeMessage = post.publicizeMessage
            self.disabledPublicizeConnectionIDs = post.disabledPublicizeConnectionIDs()
        } else {
            self.publicizeMessage = nil
            self.disabledPublicizeConnectionIDs = []
        }
    }

    // MARK: - Applying Changes

    /// Applies the settings to an AbstractPost instance.
    /// Only updates properties that have actually changed.
    func apply(to post: AbstractPost) {
        // More Options
        if post.mt_excerpt != excerpt {
            post.mt_excerpt = excerpt
        }
        if post.wp_slug != slug {
            post.wp_slug = slug
        }

        // Publishing
        if post.status != status {
            post.status = status
        }
        if post.dateCreated != publishDate {
            post.dateCreated = publishDate
        }
        if post.password != password {
            post.password = password
        }

        // Author
        if let authorID, post.authorID?.intValue != authorID {
            post.authorID = NSNumber(value: authorID)
        }

        // Featured Image
        if let featuredImageID {
            if post.featuredImage?.mediaID?.intValue != featuredImageID {
                // Note: Setting featured image requires fetching the Media object
                // This would typically be handled by the view model
            }
        } else if post.featuredImage != nil {
            post.featuredImage = nil
        }

        // Post-specific properties
        if let post = post as? Post {
            // Categories - only update if changed
            let currentCategoryIDs = Set((post.categories ?? []).compactMap { $0.categoryID?.intValue })
            if currentCategoryIDs != categoryIDs {
                // Note: Updating categories requires fetching PostCategory objects
                // This would typically be handled by the view model
            }

            if post.tags != tags {
                post.tags = tags
            }

            if let postFormat, post.postFormat != postFormat {
                post.postFormat = postFormat
            }

            if post.isStickyPost != isStickyPost {
                post.isStickyPost = isStickyPost
            }

            // Social settings
            if post.publicizeMessage != publicizeMessage {
                post.publicizeMessage = publicizeMessage
            }

            // Update disabled connections
            let currentDisabledIDs = post.disabledPublicizeConnectionIDs()
            if currentDisabledIDs != disabledPublicizeConnectionIDs {
                // Remove all current disabled connections
                for connectionID in currentDisabledIDs {
                    post.enablePublicizeConnection(with: connectionID)
                }
                // Add new disabled connections
                for connectionID in disabledPublicizeConnectionIDs {
                    post.disablePublicizeConnection(with: connectionID)
                }
            }
        }

        // Page-specific properties
        if let page = post as? Page {
            if page.parentID?.intValue != parentPageID {
                page.parentID = parentPageID.map { NSNumber(value: $0) }
            }
        }
    }

    // MARK: - Diff Generation

    /// Creates RemotePostUpdateParameters representing the changes from the original settings.
    func makeUpdateParameters(from original: PostSettings) -> RemotePostUpdateParameters {
        var parameters = RemotePostUpdateParameters()

        // More Options
        if excerpt != original.excerpt {
            parameters.excerpt = excerpt
        }
        if slug != original.slug {
            parameters.slug = slug
        }

        // Publishing
        if status != original.status {
            parameters.status = status
        }
        if publishDate != original.publishDate {
            parameters.date = publishDate
        }
        if password != original.password {
            parameters.password = password
        }

        // Author
        if authorID != original.authorID {
            parameters.authorID = authorID
        }

        // Featured Image
        if featuredImageID != original.featuredImageID {
            parameters.featuredImageID = featuredImageID
        }

        // Post-specific
        if postFormat != original.postFormat {
            parameters.format = postFormat
        }
        if isStickyPost != original.isStickyPost {
            parameters.isSticky = isStickyPost
        }
        if tags != original.tags {
            parameters.tags = makeTags(from: tags)
        }
        if categoryIDs != original.categoryIDs {
            parameters.categoryIDs = Array(categoryIDs)
        }

        // Page-specific
        if parentPageID != original.parentPageID {
            parameters.parentPageID = parentPageID
        }

        // Note: Social settings (publicize) are typically handled via metadata,
        // which would require additional implementation

        return parameters
    }
}

// MARK: - Private Helpers

private func makeTags(from tags: String) -> [String] {
    tags
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

// MARK: - Post Extensions

private extension Post {
    /// Returns the set of disabled publicize connection IDs.
    func disabledPublicizeConnectionIDs() -> Set<NSNumber> {
        var disabledIDs = Set<NSNumber>()

        // Get all available connections
        if let connections = blog.connections as? Set<PublicizeConnection> {
            for connection in connections {
                if let keyringID = connection.keyringConnectionID,
                   publicizeConnectionDisabledForKeyringID(keyringID) {
                    disabledIDs.insert(keyringID)
                }
            }
        }

        return disabledIDs
    }
}
