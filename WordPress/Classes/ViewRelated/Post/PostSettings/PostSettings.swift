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
    var otherTerms: [String: [String]] = [:]
    var featuredImageID: Int?
    var metadata: PostMetadata

    // MARK: - Post-specific
    var postFormat: String?
    var isStickyPost = false
    var sharing: PostSocialSharingSettings?
    var accessLevel: JetpackPostAccessLevel?
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
            accessLevel = metadata.accessLevel ?? .everybody
            allowComments = post.allowComments
            allowPings = post.allowPings
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
