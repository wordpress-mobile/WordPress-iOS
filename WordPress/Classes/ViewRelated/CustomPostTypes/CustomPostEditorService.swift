import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import WordPressShared

struct EditorContent {
    let title: String
    let content: String
}

@MainActor
protocol CustomPostEditorServiceDelegate: AnyObject {
    func editorContent(for service: CustomPostEditorService) async throws -> EditorContent
}

class CustomPostEditorService {

    private enum State {
        case newPost(PostSettings)
        /// - Parameter pending: Settings applied locally from Post Settings
        ///   but not yet saved to the server.
        case existingPost(AnyPostWithEditContext, pending: PostSettings? = nil)
    }

    private var state: State
    let details: PostTypeDetailsWithEditContext
    let client: WordPressClient
    let wpService: WpService
    let taxonomies: [SiteTaxonomy]
    private var initialSettings: PostSettings

    weak var delegate: CustomPostEditorServiceDelegate?

    var post: AnyPostWithEditContext? {
        if case .existingPost(let post, _) = state { return post }
        return nil
    }

    var hasSettingsChanges: Bool {
        settings != initialSettings
    }

    var settings: PostSettings {
        switch state {
        case let .newPost(settings):
            return settings
        case let .existingPost(post, pending):
            return pending ?? PostSettings(from: post, taxonomies: taxonomies)
        }
    }

    /// Applies settings locally without making a server call.
    /// Term resolution is deferred to the actual save.
    func applyLocally(settings: PostSettings) {
        switch state {
        case .newPost:
            state = .newPost(settings)
        case .existingPost(let post, _):
            state = .existingPost(post, pending: settings)
        }
    }

    init(
        blog: Blog,
        post: AnyPostWithEditContext?,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        wpService: WpService,
        initialSettings: PostSettings? = nil
    ) {
        self.details = details
        self.client = client
        self.wpService = wpService

        let capabilities = PostSettingsCapabilities(from: details)
        // At the moment, category & tags are separated from custom taxonomies. We can unify them as taxonomies later,
        // by which point we won't need this filter logic.
        self.taxonomies =
            (try? blog.taxonomies
                .filter { capabilities.customTaxonomySlugs.contains($0.slug) }
                .sorted(using: KeyPathComparator(\.name))) ?? []

        if let post {
            self.state = .existingPost(post)
            self.initialSettings = PostSettings(from: post, taxonomies: self.taxonomies)
        } else {
            let settings = initialSettings ?? .defaults(from: blog)
            self.state = .newPost(settings)
            self.initialSettings = settings
        }
    }

    // MARK: - Save

    private func makeTermResolutionService(endpoint: TermEndpointType) -> TermResolutionService {
        TermResolutionService(taxonomyService: AnyTermService(client: client, endpoint: endpoint))
    }

    /// Resolves any unresolved (`id == 0`) tags and custom-taxonomy terms by
    /// looking them up on the server or creating them. Required before turning
    /// settings into create/update parameters, which filter to `id > 0`.
    private func resolveTerms(in settings: PostSettings) async throws -> PostSettings {
        var settings = settings
        settings.tags = try await makeTermResolutionService(endpoint: .tags).resolveIDs(for: settings.tags)
        for taxonomy in taxonomies {
            guard let slugTerms = settings.otherTerms[taxonomy.slug] else { continue }
            settings.otherTerms[taxonomy.slug] = try await makeTermResolutionService(endpoint: taxonomy.endpoint)
                .resolveIDs(for: slugTerms)
        }
        return settings
    }

    /// Saves or publishes from post settings. Handles term resolution, optional
    /// publish status override with editor content injection, and create-or-update branching.
    func save(settings: PostSettings, publish: Bool) async throws {
        let settings = try await resolveTerms(in: settings)

        switch (state, publish) {
        case (.newPost, false):
            // Store settings locally so the editor can create the post later.
            state = .newPost(settings)

        case (.newPost, true):
            var params = settings.makeCreateParameters(taxonomies: taxonomies)
            params.status = params.status?.normalizedPublishStatus() ?? .publish

            // Update content
            if let delegate {
                let hasTitle = details.supports.map[.title] == .bool(true)
                let editorContent = try await delegate.editorContent(for: self)
                params.title = hasTitle ? editorContent.title : nil
                params.content = editorContent.content
            }

            try await create(params: params)

        case (.existingPost(let post, _), false):
            let params = settings.makeUpdateParameters(from: post, taxonomies: taxonomies)
            try await update(post: post, params: params)

        case (.existingPost(let post, _), true):
            var params = settings.makeUpdateParameters(from: post, taxonomies: taxonomies)
            params.status = PostStatus(settings.status).normalizedPublishStatus()

            // Update content
            if let delegate {
                let hasTitle = details.supports.map[.title] == .bool(true)
                let editorContent = try await delegate.editorContent(for: self)
                params.title = hasTitle ? editorContent.title : nil
                params.content = editorContent.content
            }

            try await update(post: post, params: params)
        }
    }

    /// Saves or publishes from the editor. Handles conflict checking and
    /// create-or-update branching with editor content.
    func save(content: EditorContent, publish: Bool) async throws {
        let hasTitle = details.supports.map[.title] == .bool(true)

        switch state {
        case .newPost(let settings):
            // Resolve any new tags / custom terms (id == 0) before they get
            // filtered out by `makeCreateParameters`.
            let resolved = try await resolveTerms(in: settings)
            var params = resolved.makeCreateParameters(taxonomies: taxonomies)
            params.status = publish ? (params.status?.normalizedPublishStatus() ?? .publish) : .draft
            params.title = hasTitle ? content.title : nil
            params.content = content.content
            try await create(params: params)

        case .existingPost(let post, let pending):
            var params: PostUpdateParams
            if let pending {
                let resolved = try await resolveTerms(in: pending)
                params = resolved.makeUpdateParameters(from: post, taxonomies: taxonomies)
            } else {
                params = PostUpdateParams(meta: nil)
            }
            if publish {
                params.status = pending.map { PostStatus($0.status).normalizedPublishStatus() } ?? .publish
            }
            params.title = hasTitle ? content.title : nil
            params.content = content.content
            try await update(post: post, params: params)
        }
    }

    /// Updates the post and refreshes the local post list cache.
    @discardableResult
    private func update(post: AnyPostWithEditContext, params: PostUpdateParams) async throws -> AnyPostWithEditContext {
        guard try await !hasBeenModified(post: post) else { throw PostUpdateError.conflicts }

        let endpoint = details.toPostEndpointType()
        let updatedPost = try await wpService.posts()
            .updatePost(endpointType: endpoint, postId: post.id, params: params)
        state = .existingPost(updatedPost)
        initialSettings = settings

        return updatedPost
    }

    /// Creates a new post and refreshes the local post list cache.
    @discardableResult
    private func create(params: PostCreateParams) async throws -> AnyPostWithEditContext {
        let endpoint = details.toPostEndpointType()
        let createdPost = try await wpService.posts().createPost(endpointType: endpoint, params: params)
        state = .existingPost(createdPost)
        initialSettings = settings
        return createdPost
    }

    /// Checks whether the post has been modified on the server since it was last fetched.
    private func hasBeenModified(post: AnyPostWithEditContext) async throws -> Bool {
        let lastModified = try await client.api.posts
            .filterRetrieveWithEditContext(
                postEndpointType: details.toPostEndpointType(),
                postId: post.id,
                params: .init(),
                fields: [.modified]
            )
            .data
            .modified
        return lastModified != post.modified
    }
}

extension CustomPostEditorService {
    // Used in unit tests.
    func inspectPendingSettings() -> PostSettings? {
        if case .existingPost(_, let pending) = state {
            return pending
        }
        return nil
    }

    // Used in unit tests.
    func inspectNewPostSettings() -> PostSettings? {
        if case .newPost(let settings) = state {
            return settings
        }
        return nil
    }
}

enum PostUpdateError: LocalizedError {
    case conflicts

    var errorDescription: String? {
        NSLocalizedString(
            "customPostEditor.error.conflict.message",
            value: "The post you are trying to save has been changed in the meantime.",
            comment: "Error message shown when the post was modified by another user while editing"
        )
    }
}

private extension PostStatus {
    /// Maps a user-selected status to the one used by a publish action.
    /// `.future`, `.private`, and `.pending` are preserved because they carry
    /// their own publishing semantics (scheduled, password/private visibility,
    /// submit for review); every other selection (draft) collapses to
    /// `.publish` so the post is published normally.
    func normalizedPublishStatus() -> PostStatus {
        switch self {
        case .future: return .future
        case .private: return .private
        case .pending: return .pending
        default: return .publish
        }
    }
}
