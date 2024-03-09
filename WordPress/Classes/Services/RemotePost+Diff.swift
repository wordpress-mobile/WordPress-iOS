import WordPressKit

extension RemotePostUpdateParameters {
    /// Returns a diff between the posts.
    static func change(from lhs: AbstractPost, to rhs: AbstractPost) -> RemotePostUpdateParameters {
        let changes = RemotePostUpdateParameters()

        if lhs.authorID != rhs.authorID, rhs.authorID != 0 {
            changes.authorID = rhs.authorID?.intValue
        }
        if lhs.postTitle != rhs.postTitle {
            changes.title = rhs.postTitle
        }
        if lhs.content != rhs.content {
            changes.content = rhs.content
        }
        if lhs.password != rhs.password {
            changes.password = rhs.password
        }
        if lhs.mt_excerpt != rhs.mt_excerpt {
            changes.excerpt = rhs.mt_excerpt
        }
        if lhs.wp_slug != rhs.wp_slug {
            changes.slug = rhs.wp_slug
        }
        if lhs.featuredImage?.mediaID != rhs.featuredImage?.mediaID {
            changes.featuredImageID = rhs.featuredImage?.mediaID?.intValue
        }

        switch (lhs, rhs) {
        case let (lhs, rhs) as (Page, Page):
            if lhs.parentID != rhs.parentID {
                changes.parentPageID = rhs.parentID?.intValue
            }
        case let (lhs, rhs) as (Post, Post):
            if lhs.postFormat != rhs.postFormat {
                changes.format = rhs.postFormat
            }
            if (lhs.categories ?? []).map(\.categoryID) != (rhs.categories ?? []).map(\.categoryID) {
                changes.categoryIDs = (rhs.categories ?? []).map(\.categoryID).map(\.intValue)
            }
            //        public var tags: [String]?
            if lhs.isStickyPost != rhs.isStickyPost {
                changes.isSticky = rhs.isStickyPost
            }
        default:
            break
        }
        return changes
    }
}

extension RemotePost {
    // TODO: It'll be easier to create this using RemotePostCreateParameters

    /// Returns a diff requires to update the given post to the reciever.
    func changes(from other: RemotePost) -> RemotePostUpdateParameters {
        let changes = RemotePostUpdateParameters()
        if other.status != status, let status = status {
            changes.status = status
        }
        if other.date != date {
            changes.date = date
        }
        if other.authorID != authorID {
            changes.title = authorID
        }
        if content != other.content {
            changes.content = content
        }
        return changes
    }

    // TODO: should "publish" first upload the latest revision?
    // TODO: A temporary solution for applying the diff
    func apply(_ changes: RemotePostUpdateParameters) {
        if let status = changes.status {
            self.status = status
        }
        if let date = changes.date {
            self.date = date
        }
        //        if let authorID = changes.authorID {
        //            post.authorID = authorID
        //        }
        if let title = changes.title {
            self.title = title
        }
        if let content = changes.content {
            self.content = content
        }
        if let password = changes.password {
            self.password = password
        }
        // TODO: Update remaining options
    }
}
