import WordPressAPI
import WordPressAPIInternal

// MARK: - PostUpdateParams Diffing & Conflict Detection

extension PostUpdateParams {

    /// Checks whether any field in this params conflicts with the changes
    /// between `original` and `latest` server snapshots.
    ///
    /// A conflict exists for a field when all three conditions hold:
    /// 1. The client is changing the field (non-nil, or non-empty for arrays)
    /// 2. The server changed the field (`latest.field != original.field`)
    /// 3. The values didn't converge (`latest.field != self.field`)
    func hasConflicts(
        from original: AnyPostWithEditContext,
        to latest: AnyPostWithEditContext
    ) -> Bool {
        let serverChanges = PostUpdateParams.changes(from: original, to: latest)
        return hasConflicts(with: serverChanges)
    }

    /// Computes a diff between two post snapshots, returning a `PostUpdateParams`
    /// with only the changed fields populated. Nil/empty fields mean unchanged.
    static func changes(
        from original: AnyPostWithEditContext,
        to latest: AnyPostWithEditContext
    ) -> PostUpdateParams {
        var diff = PostUpdateParams(meta: nil)
        if original.slug != latest.slug {
            diff.slug = latest.slug
        }
        if original.status != latest.status {
            diff.status = latest.status
        }
        if original.password != latest.password {
            diff.password = latest.password
        }
        if original.author != latest.author {
            diff.author = latest.author
        }
        if original.title?.raw != latest.title?.raw {
            diff.title = latest.title?.raw
        }
        if original.content.raw != latest.content.raw {
            diff.content = latest.content.raw
        }
        if original.excerpt?.raw != latest.excerpt?.raw {
            diff.excerpt = latest.excerpt?.raw
        }
        if original.featuredMedia != latest.featuredMedia {
            diff.featuredMedia = latest.featuredMedia
        }
        if original.commentStatus != latest.commentStatus {
            diff.commentStatus = latest.commentStatus
        }
        if original.pingStatus != latest.pingStatus {
            diff.pingStatus = latest.pingStatus
        }
        if original.format != latest.format {
            diff.format = latest.format
        }
        if original.sticky != latest.sticky {
            diff.sticky = latest.sticky
        }
        if original.dateGmt != latest.dateGmt {
            diff.dateGmt = latest.dateGmt
        }
        if original.parent != latest.parent {
            diff.parent = latest.parent
        }
        if Set(original.categories ?? []) != Set(latest.categories ?? []) {
            diff.categories = latest.categories ?? []
        }
        if Set(original.tags ?? []) != Set(latest.tags ?? []) {
            diff.tags = latest.tags ?? []
        }
        // TODO: template, and menuOrder are not checked because the
        // current editor does not populate them.
        return diff
    }

    /// Checks whether two `PostUpdateParams` overlap on any field with
    /// different values. Both params must have a field set (non-nil / non-empty
    /// for arrays) for it to count as a conflict.
    func hasConflicts(with other: PostUpdateParams) -> Bool {
        if let slug, let otherSlug = other.slug, slug != otherSlug {
            return true
        }
        if let status, let otherStatus = other.status, status != otherStatus {
            return true
        }
        if let password, let otherPassword = other.password, password != otherPassword {
            return true
        }
        if let author, let otherAuthor = other.author, author != otherAuthor {
            return true
        }
        if let title, let otherTitle = other.title, title != otherTitle {
            return true
        }
        if let content, let otherContent = other.content, content != otherContent {
            return true
        }
        if let excerpt, let otherExcerpt = other.excerpt, excerpt != otherExcerpt {
            return true
        }
        if let featuredMedia, let otherFeaturedMedia = other.featuredMedia, featuredMedia != otherFeaturedMedia {
            return true
        }
        if let commentStatus, let otherCommentStatus = other.commentStatus, commentStatus != otherCommentStatus {
            return true
        }
        if let pingStatus, let otherPingStatus = other.pingStatus, pingStatus != otherPingStatus {
            return true
        }
        if let format, let otherFormat = other.format, format != otherFormat {
            return true
        }
        if let sticky, let otherSticky = other.sticky, sticky != otherSticky {
            return true
        }
        if let dateGmt, let otherDateGmt = other.dateGmt, dateGmt != otherDateGmt {
            return true
        }
        if let parent, let otherParent = other.parent, parent != otherParent {
            return true
        }
        if !categories.isEmpty, !other.categories.isEmpty, Set(categories) != Set(other.categories) {
            return true
        }
        if !tags.isEmpty, !other.tags.isEmpty, Set(tags) != Set(other.tags) {
            return true
        }
        return false
    }
}
