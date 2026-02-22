import Foundation
import WordPressAPIInternal
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

        static func == (lhs: Author, rhs: Author) -> Bool {
            // The displayName may be fetched locally.
            // Only id is sent to the API for updating author.
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    var excerpt: String
    var slug: String
    var status: BasePost.Status
    var publishDate: Date?
    var password: String?
    var author: Author?
    var categoryIDs: Set<Int> = []
    var tags: String = ""
    var otherTerms: [String: [String]] = [:]
    var featuredImageID: Int?
    var metadata: PostMetadata

    // MARK: - Post-specific
    var postFormat: String?
    var isStickyPost = false
    var sharing: PostSocialSharingSettings?
    var allowComments = true
    var allowPings = true

    // MARK: - Page-specific
    var parentPageID: Int?

    // MARK: - Initialization

    /// Creates PostSettings from an AbstractPost instance.
    init(from post: AbstractPost) {
        excerpt = post.mt_excerpt ?? ""
        slug = post.wp_slug ?? ""
        status = post.status ?? .draft
        publishDate = post.shouldPublishImmediately() ? nil : post.dateCreated
        password = post.password

        if let authorID = post.authorID?.intValue, authorID > 0 {
            author = Author(
                id: authorID,
                displayName: post.author ?? "–",
                avatarURL: post.authorAvatarURL.flatMap(URL.init)
            )
        }

        featuredImageID = post.featuredImage?.mediaID?.intValue
        otherTerms = post.parsedOtherTerms

        metadata = PostMetadata(post)

        switch post {
        case let post as Post:
            postFormat = post.postFormat
            isStickyPost = post.isStickyPost
            tags = post.tags ?? ""
            categoryIDs = Set((post.categories ?? []).map {
                $0.categoryID.intValue
            })
            sharing = PostSocialSharingSettings.make(for: post)
            allowComments = post.allowComments
            allowPings = post.allowPings
        case let page as Page:
            parentPageID = page.parentID?.intValue
        default:
            wpAssertionFailure("unsupported post type", userInfo: ["post_type": String(describing: type(of: post))])
        }
    }

    /// Creates PostSettings from an AnyPostWithEditContext (REST API) instance.
    init(from post: AnyPostWithEditContext) {
        excerpt = post.excerpt?.raw ?? ""
        slug = post.slug
        status = BasePost.Status(post.status)
        // For drafts that haven't been explicitly scheduled, treat as "publish immediately"
        if status == .draft || status == .pending {
            publishDate = nil
        } else {
            publishDate = post.dateGmt
        }
        password = post.password

        if let authorId = post.author {
            // FIXME: author name is not returned in the REST API.
            // But We should be able to fetch the author name before showing the Post Settings.
            author = Author(id: Int(authorId), displayName: "–", avatarURL: nil)
        }

        featuredImageID = post.featuredMedia.map { Int($0) }
        // FIXME: Resolve custom taxonomy term names from term IDs returned by the REST API
        otherTerms = [:]

        // FIXME: Post metadata is not supported yet. Require wordpress-rs changes.
        metadata = PostMetadata(from: .init())

        postFormat = post.format.map { $0.id }
        isStickyPost = post.sticky ?? false
        // FIXME: Resolve tag names from term IDs returned by the REST API
        tags = ""
        categoryIDs = Set((post.categories ?? []).map { Int($0) })
        allowComments = post.commentStatus == .open
        allowPings = post.pingStatus == .open

        // TODO: The Post Settings UI currently only supports Pages
        // The parent post is available in `post.parent`
        parentPageID = nil

        // Social sharing (Publicize) is not available for REST API posts
        sharing = nil
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

        if !RemotePost.compare(otherTerms: post.parsedOtherTerms, withAnother: otherTerms) {
            post.parsedOtherTerms = otherTerms
        }

        var postMetadataContainer = PostMetadataContainer(post)
        if PostMetadata(from: postMetadataContainer) != metadata {
            metadata.encode(in: &postMetadataContainer)
            do {
                post.rawMetadata = try postMetadataContainer.encode()
            } catch {
                wpAssertionFailure("failed to encode metadata")
            }
        }

        switch post {
        case let post as Post:
            // Update tags
            if post.tags != tags {
                post.tags = tags
            }

            // Update categories
            let currentCategoryIDs = Set((post.categories ?? []).map { $0.categoryID.intValue })
            if currentCategoryIDs != categoryIDs {
                // Find category objects for the IDs
                let allCategories = post.blog.categories ?? []
                let selectedCategories = allCategories.filter { category in
                    categoryIDs.contains(category.categoryID.intValue)
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

            // Update discussion settings
            if post.allowComments != allowComments {
                post.allowComments = allowComments
            }
            if post.allowPings != allowPings {
                post.allowPings = allowPings
            }

            if let sharing {
                for connection in sharing.services.flatMap(\.connections) {
                    let keyringID = NSNumber(value: connection.keyringID)
                    if !post.publicizeConnectionDisabledForKeyringID(keyringID) != connection.enabled {
                        if connection.enabled {
                            post.enablePublicizeConnectionWithKeyringID(keyringID)
                        } else {
                            post.disablePublicizeConnectionWithKeyringID(keyringID)
                        }
                    }
                }
                if post.publicizeMessage != sharing.message {
                    post.publicizeMessage = sharing.message
                }
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

    /// Creates `PostUpdateParams` representing the diff between the post and
    /// the current settings, for use with the WordPress REST API.
    func makeUpdateParameters(from post: AnyPostWithEditContext) -> PostUpdateParams {
        var slug: String?
        if post.slug != self.slug {
            slug = self.slug
        }

        var status: PostStatus?
        if BasePost.Status(post.status) != self.status {
            status = PostStatus(self.status)
        }

        var password: String?
        if post.password != self.password {
            password = self.password ?? ""
        }

        var author: UserId?
        if post.author.map({ Int($0) }) != self.author?.id, let authorId = self.author?.id {
            author = UserId(Int64(authorId))
        }

        var excerpt: String?
        if (post.excerpt?.raw ?? "") != self.excerpt {
            excerpt = self.excerpt
        }

        var featuredMedia: MediaId?
        if post.featuredMedia.map({ Int($0) }) != self.featuredImageID {
            featuredMedia = self.featuredImageID.map { MediaId(Int64($0)) } ?? MediaId(0)
        }

        var commentStatus: PostCommentStatus?
        let postAllowsComments = post.commentStatus == .open
        if postAllowsComments != self.allowComments {
            commentStatus = self.allowComments ? .open : .closed
        }

        var pingStatus: PostPingStatus?
        let postAllowsPings = post.pingStatus == .open
        if postAllowsPings != self.allowPings {
            pingStatus = self.allowPings ? .open : .closed
        }

        var format: PostFormat?
        let postFormatSlug = post.format.map { $0.id }
        if postFormatSlug != self.postFormat {
            format = self.postFormat.flatMap { PostFormat.from(slug: $0) }
        }

        var sticky: Bool?
        if (post.sticky ?? false) != self.isStickyPost {
            sticky = self.isStickyPost
        }

        var categories: [TermId] = []
        let postCategoryIDs = Set((post.categories ?? []).map { Int($0) })
        if postCategoryIDs != self.categoryIDs {
            categories = self.categoryIDs.map { TermId(Int64($0)) }
        }

        // FIXME: Not implemented yet.
        // Tags are stored as comma-separated names for AbstractPost, but as IDs for remote posts.
        // For remote posts, tag changes would need ID resolution. Skip for now.
        // var tags: [TermId] = []

        // TODO: The Post Settings UI currently only supports Pages
//        var parent: PostId?
//        let postParentPageID = post.parent.map { Int($0) }
//        if postParentPageID != self.parentPageID {
//            parent = self.parentPageID.map { PostId(Int64($0)) } ?? PostId(0)
//        }

        return PostUpdateParams(
            slug: slug,
            status: status,
            password: password,
            author: author,
            excerpt: excerpt,
            featuredMedia: featuredMedia,
            commentStatus: commentStatus,
            pingStatus: pingStatus,
            format: format,
            meta: nil,
            sticky: sticky,
            categories: categories,
            tags: [],
            parent: nil
        )
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
        return getCategoryNames(for: post.blog)
    }

    func getCategoryNames(for blog: Blog) -> [String] {
        var categories: [Int: String] = [:]
        for category in blog.categories ?? [] {
            categories[category.categoryID.intValue] = category.categoryName
        }
        return categoryIDs.compactMap { categories[$0] }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { $0.stringByDecodingXMLCharacters() }
    }

    func getTerms(forTaxonomySlug taxonomySlug: String) -> [String] {
        otherTerms[taxonomySlug] ?? []
    }

    mutating func setTerms(_ terms: String, forTaxonomySlug taxonomySlug: String) {
        otherTerms[taxonomySlug] = AbstractPost.makeTags(from: terms)
    }
}

// MARK: - PostFormat Slug

extension PostFormat {
    // TODO: Export from wordpress-rs
    var id: String {
        switch self {
        case .standard: return "standard"
        case .aside: return "aside"
        case .chat: return "chat"
        case .gallery: return "gallery"
        case .link: return "link"
        case .image: return "image"
        case .quote: return "quote"
        case .status: return "status"
        case .video: return "video"
        case .audio: return "audio"
        case .custom(let value): return value
        }
    }
}

// MARK: - Status Mapping

extension BasePost.Status {
    init(_ status: PostStatus) {
        switch status {
        case .publish: self = .publish
        case .draft: self = .draft
        case .pending: self = .pending
        case .private: self = .publishPrivate
        case .future: self = .scheduled
        case .trash: self = .trash
        case .custom:
            wpAssertionFailure("unexpected custom post status")
            self = .draft
        }
    }
}

extension PostStatus {
    init(_ status: BasePost.Status) {
        switch status {
        case .publish: self = .publish
        case .draft: self = .draft
        case .pending: self = .pending
        case .publishPrivate: self = .private
        case .scheduled: self = .future
        case .trash: self = .trash
        case .deleted: self = .trash
        }
    }
}

/// A value-type representation of `PublicizeService` for the current blog that's simplified for the auto-sharing flow.
struct PostSocialSharingSettings: Hashable {
    var services: [Service]
    var message: String
    var sharingLimit: PublicizeInfo.SharingLimit?

    struct Service: Hashable {
        let name: PublicizeService.ServiceName
        var connections: [Connection]
    }

    struct Connection: Hashable {
        let account: String
        let keyringID: Int
        var enabled: Bool
    }

    static func make(for post: Post) -> PostSocialSharingSettings? {
        guard let context = post.managedObjectContext else {
            wpAssertionFailure("missing moc")
            return nil
        }

        let connections = post.blog.sortedConnections

        // first, build a dictionary to categorize the connections.
        var connectionsMap = [PublicizeService.ServiceName: [PublicizeConnection]]()
        connections.filter { !$0.requiresUserAction() }.forEach { connection in
            let name = PublicizeService.ServiceName(rawValue: connection.service) ?? .unknown
            var serviceConnections = connectionsMap[name] ?? []
            serviceConnections.append(connection)
            connectionsMap[name] = serviceConnections
        }

        let publicizeServices: [PublicizeService]
        do {
            publicizeServices = try PublicizeService.allPublicizeServices(in: context)
        } catch {
            wpAssertionFailure("failed to fetch services", userInfo: ["error": error.localizedDescription])
            return nil
        }

        let services = publicizeServices.compactMap { service -> PostSocialSharingSettings.Service? in
            // skip services without connections.
            guard let serviceConnections = connectionsMap[service.name],
                  !serviceConnections.isEmpty else {
                return nil
            }

            return PostSocialSharingSettings.Service(
                name: service.name,
                connections: serviceConnections.map {
                    .init(account: $0.externalDisplay,
                          keyringID: $0.keyringConnectionID.intValue,
                          enabled: !post.publicizeConnectionDisabledForKeyringID($0.keyringConnectionID))
                }
            )
        }

        return PostSocialSharingSettings(
            services: services,
            message: post.publicizeMessage ?? post.titleForDisplay(),
            sharingLimit: post.blog.sharingLimit
        )
    }
}
