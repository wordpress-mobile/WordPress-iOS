import Foundation
import WordPressAPIInternal
import WordPressData
import WordPressKit
import WordPressShared

/// A plain data structure representing the subset of post/page settings that can be edited in PostSettingsView.
/// Used for change tracking and to separate UI state from Core Data objects.
struct PostSettings: Hashable {
    struct Term: Hashable {
        let id: Int
        var name: String

        // Two terms are the same if they share the same non-zero ID or
        // the same name. This handles the case where a term with `id == 0`
        // (unsaved) matches a server-confirmed term by name.
        static func == (lhs: Term, rhs: Term) -> Bool {
            let bothExistOnServer = lhs.id != 0 && rhs.id != 0
            if bothExistOnServer {
                return lhs.id == rhs.id
            }
            return lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            // Hash only by name so that terms equal by name land in the
            // same bucket, satisfying the Hashable contract.
            hasher.combine(name)
        }
    }

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
    /// Category IDs are kept as plain integers (not `[Term]`) because categories
    /// are resolved from `Blog.categories`, which is synced to Core Data and
    /// available locally. Unlike tags and custom terms, there's no need for
    /// async ID-to-name resolution.
    var categoryIDs: Set<Int> = []
    var tags: [Term] = []
    var otherTerms: [String: [Term]] = [:]
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

    /// Creates settings for a new post from optional stored create parameters.
    ///
    /// When `params` is nil (first open), all fields use sensible defaults.
    /// When non-nil, the stored values from a previous Post Settings session
    /// are applied on top of the defaults.
    init(from params: PostCreateParams, taxonomies: [SiteTaxonomy] = []) {
        excerpt = params.excerpt ?? ""
        slug = params.slug ?? ""
        status = .draft
        publishDate = nil
        password = params.password
        metadata = PostMetadata(from: .init())

        if let author = params.author {
            self.author = Author(id: Int(author), displayName: "–", avatarURL: nil)
        }
        if let featuredMedia = params.featuredMedia, featuredMedia > 0 {
            featuredImageID = Int(featuredMedia)
        }
        if let commentStatus = params.commentStatus {
            allowComments = commentStatus == .open
        }
        if let pingStatus = params.pingStatus {
            allowPings = pingStatus == .open
        }
        if let format = params.format {
            postFormat = format.id
        }
        if let sticky = params.sticky {
            isStickyPost = sticky
        }
        if !params.categories.isEmpty {
            categoryIDs = Set(params.categories.map { Int($0) })
        }
        if !params.tags.isEmpty {
            tags = params.tags.map { Term(id: Int($0), name: "") }
        }

        // Custom taxonomy terms
        var otherTerms: [String: [Term]] = [:]
        for taxonomy in taxonomies {
            let termIds = params.additionalFields?.termIdsForKey(key: taxonomy.restBase) ?? []
            if !termIds.isEmpty {
                otherTerms[taxonomy.slug] = termIds.map { Term(id: Int($0), name: "") }
            }
        }
        self.otherTerms = otherTerms
    }

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
        otherTerms = post.parsedOtherTerms.mapValues { names in
            names.map { Term(id: 0, name: $0) }
        }

        metadata = PostMetadata(post)

        switch post {
        case let post as Post:
            postFormat = post.postFormat
            isStickyPost = post.isStickyPost
            tags = AbstractPost.makeTags(from: post.tags ?? "").map { Term(id: 0, name: $0) }
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
    init(from post: AnyPostWithEditContext, taxonomies: [SiteTaxonomy] = []) {
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

        if let id = post.featuredMedia, id > 0 {
            featuredImageID = Int(id)
        }

        var otherTerms: [String: [Term]] = [:]
        for taxonomy in taxonomies {
            let termIds = post.additionalFields?.termIdsForKey(key: taxonomy.restBase) ?? []
            if !termIds.isEmpty {
                // Term names will be resolved asynchronously in PostSettingsViewModel
                otherTerms[taxonomy.slug] = termIds.map { Term(id: Int($0), name: "") }
            }
        }
        self.otherTerms = otherTerms

        // FIXME: Post metadata is not supported yet. Require wordpress-rs changes.
        metadata = PostMetadata(from: .init())

        postFormat = post.format.map { $0.id }
        isStickyPost = post.sticky ?? false
        // Tag names will be resolved asynchronously in PostSettingsViewModel
        tags = (post.tags ?? []).map { Term(id: Int($0), name: "") }
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

        let otherTermNames = otherTerms.mapValues { $0.map(\.name) }
        if !RemotePost.compare(otherTerms: post.parsedOtherTerms, withAnother: otherTermNames) {
            post.parsedOtherTerms = otherTermNames
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
            let tagsString = tags.map(\.name).joined(separator: ", ")
            if post.tags != tagsString {
                post.tags = tagsString
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
    func makeUpdateParameters(from post: AnyPostWithEditContext, taxonomies: [SiteTaxonomy] = []) -> PostUpdateParams {
        var params = PostUpdateParams(meta: nil)

        if post.slug != self.slug {
            params.slug = self.slug
        }

        if BasePost.Status(post.status) != self.status {
            params.status = PostStatus(self.status)
        }

        if post.password != self.password {
            params.password = self.password ?? ""
        }

        if post.author.map({ Int($0) }) != self.author?.id, let authorId = self.author?.id {
            params.author = UserId(Int64(authorId))
        }

        if (post.excerpt?.raw ?? "") != self.excerpt {
            params.excerpt = self.excerpt
        }

        if post.featuredMedia.map({ Int($0) }) != self.featuredImageID {
            params.featuredMedia = self.featuredImageID.map { MediaId(Int64($0)) } ?? MediaId(0)
        }

        let postAllowsComments = post.commentStatus == .open
        if postAllowsComments != self.allowComments {
            params.commentStatus = self.allowComments ? .open : .closed
        }

        let postAllowsPings = post.pingStatus == .open
        if postAllowsPings != self.allowPings {
            params.pingStatus = self.allowPings ? .open : .closed
        }

        if post.format.map({ $0.id }) != self.postFormat {
            params.format = self.postFormat.flatMap { PostFormat.from(slug: $0) }
        }

        // Publish date: nil means "publish immediately" for drafts/pending
        let originalStatus = BasePost.Status(post.status)
        let originalPublishDate: Date? = (originalStatus == .draft || originalStatus == .pending) ? nil : post.dateGmt
        if originalPublishDate != self.publishDate {
            params.dateGmt = self.publishDate
        }

        if (post.sticky ?? false) != self.isStickyPost {
            params.sticky = self.isStickyPost
        }

        let postCategoryIDs = Set((post.categories ?? []).map { Int($0) })
        if postCategoryIDs != self.categoryIDs {
            params.categories = self.categoryIDs.map { TermId(Int64($0)) }
        }

        // `resolveUnknownIDs` now creates new terms on the server, so `id == 0`
        // terms should not reach this point. Filter defensively as a safety net.
        let postTagIDs = Set((post.tags ?? []).map { Int($0) })
        let settingsTagIDs = Set(self.tags.filter { $0.id > 0 }.map(\.id))
        if postTagIDs != settingsTagIDs {
            params.tags = self.tags.filter { $0.id > 0 }.map { TermId(Int64($0.id)) }
        }

        // Custom taxonomy terms
        var customTermChanges: [String: [TermId]] = [:]
        for (slug, terms) in self.otherTerms {
            guard let taxonomy = taxonomies.first(where: { $0.slug == slug }) else { continue }
            let restBase = taxonomy.restBase
            let termIds = terms.filter { $0.id > 0 }.map { TermId(Int64($0.id)) }
            let originalIds = post.additionalFields?.termIdsForKey(key: restBase) ?? []
            if Set(termIds) != Set(originalIds) {
                customTermChanges[restBase] = termIds
            }
        }
        if !customTermChanges.isEmpty {
            params.additionalFields = AnyJson.fromTermIdMap(map: customTermChanges)
        }

        // TODO: The Post Settings UI currently only supports Pages
//        let postParentPageID = post.parent.map { Int($0) }
//        if postParentPageID != self.parentPageID {
//            params.parent = self.parentPageID.map { PostId(Int64($0)) } ?? PostId(0)
//        }

        return params
    }

    /// Creates `PostCreateParams` from the current settings for a new post.
    func makeCreateParameters(from existing: PostCreateParams, taxonomies: [SiteTaxonomy] = []) -> PostCreateParams {
        let tagIds = tags.filter { $0.id > 0 }.map { TermId(Int64($0.id)) }
        let categoryIds = categoryIDs.map { TermId(Int64($0)) }

        // Custom taxonomy terms
        var customTerms: [String: [TermId]] = [:]
        for (slug, terms) in otherTerms {
            guard let taxonomy = taxonomies.first(where: { $0.slug == slug }) else { continue }
            let termIds = terms.filter { $0.id > 0 }.map { TermId(Int64($0.id)) }
            if !termIds.isEmpty {
                customTerms[taxonomy.restBase] = termIds
            }
        }
        let additionalFields: AnyJson? = customTerms.isEmpty
            ? nil
            : AnyJson.fromTermIdMap(map: customTerms)

        var params = existing
        params.dateGmt = publishDate
        params.slug = slug.isEmpty ? nil : slug
        params.status = PostStatus(status)
        params.password = password
        params.author = author.map { UserId(Int64($0.id)) }
        params.excerpt = excerpt.isEmpty ? nil : excerpt
        params.featuredMedia = featuredImageID.map { MediaId(Int64($0)) }
        params.commentStatus = allowComments ? .open : .closed
        params.pingStatus = allowPings ? .open : .closed
        params.format = postFormat.flatMap { PostFormat.from(slug: $0) }
        params.sticky = isStickyPost ? true : nil
        params.categories = categoryIds
        params.tags = tagIds
        params.additionalFields = additionalFields
        return params
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

    func getTerms(forTaxonomySlug taxonomySlug: String) -> [Term] {
        otherTerms[taxonomySlug] ?? []
    }

    mutating func setTerms(_ terms: String, forTaxonomySlug taxonomySlug: String) {
        otherTerms[taxonomySlug] = AbstractPost.makeTags(from: terms).map {
            Term(id: 0, name: $0)
        }
    }
}

// MARK: - PostFormat Slug

extension PostFormat {
    static func from(slug: String) -> PostFormat {
        switch slug {
        case "standard": return .standard
        case "aside": return .aside
        case "chat": return .chat
        case "gallery": return .gallery
        case "link": return .link
        case "image": return .image
        case "quote": return .quote
        case "status": return .status
        case "video": return .video
        case "audio": return .audio
        default: return .custom(slug)
        }
    }

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
