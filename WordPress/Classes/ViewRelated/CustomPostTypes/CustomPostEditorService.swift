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
        case newPost(PostCreateParams)
        /// - Parameter pending: Settings applied locally from Post Settings
        ///   but not yet saved to the server.
        case existingPost(AnyPostWithEditContext, pending: PostSettings? = nil)
    }

    private var state: State
    let details: PostTypeDetailsWithEditContext
    let client: WordPressClient
    let service: WordPressAPIInternal.PostService
    let taxonomies: [SiteTaxonomy]

    weak var delegate: CustomPostEditorServiceDelegate?

    var post: AnyPostWithEditContext? {
        if case .existingPost(let post, _) = state { return post }
        return nil
    }

    var settings: PostSettings {
        switch state {
        case let .newPost(params):
            return PostSettings(from: params, taxonomies: taxonomies)
        case let .existingPost(post, pending):
            return pending ?? PostSettings(from: post, taxonomies: taxonomies)
        }
    }

    /// Applies settings locally without making a server call.
    /// Term resolution is deferred to the actual save.
    func applyLocally(settings: PostSettings) {
        switch state {
        case .newPost(let existing):
            let params = settings.makeCreateParameters(from: existing, taxonomies: taxonomies)
            state = .newPost(params)
        case .existingPost(let post, _):
            state = .existingPost(post, pending: settings)
        }
    }

    init(
        blog: Blog,
        post: AnyPostWithEditContext?,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        service: WordPressAPIInternal.PostService
    ) {
        if let post {
            self.state = .existingPost(post)
        } else {
            self.state = .newPost(PostCreateParams.defaultParams(from: blog))
        }
        self.details = details
        self.client = client
        self.service = service

        let capabilities = PostSettingsCapabilities(from: details)
        // At the moment, category & tags are separated from custom taxonomies. We can unify them as taxonomies later,
        // by which point we won't need this filter logic.
        self.taxonomies = (try? blog.taxonomies
            .filter { capabilities.customTaxonomySlugs.contains($0.slug) }
            .sorted(using: KeyPathComparator(\.name))) ?? []
    }

    // MARK: - Save

    private func makeTermResolutionService(endpoint: TermEndpointType) -> TermResolutionService {
        TermResolutionService(taxonomyService: AnyTermService(client: client, endpoint: endpoint))
    }

    /// Saves or publishes from post settings. Handles term resolution, optional
    /// publish status override with editor content injection, and create-or-update branching.
    func save(settings: PostSettings, publish: Bool) async throws {
        var settings = settings
        settings.tags = try await makeTermResolutionService(endpoint: .tags).resolveIDs(for: settings.tags)
        for taxonomy in taxonomies {
            guard let slugTerms = settings.otherTerms[taxonomy.slug] else { continue }
            settings.otherTerms[taxonomy.slug] = try await makeTermResolutionService(endpoint: taxonomy.endpoint)
                .resolveIDs(for: slugTerms)
        }

        switch (state, publish) {
        case (.newPost(let existing), false):
            // Store settings locally so the editor can create the post later.
            let params = settings.makeCreateParameters(from: existing, taxonomies: taxonomies)
            state = .newPost(params)

        case (.newPost(let existing), true):
            var params = settings.makeCreateParameters(from: existing, taxonomies: taxonomies)

            // Update content
            if let delegate {
                let hasTitle = details.supports.map[.title] == .bool(true)
                let editorContent = try await delegate.editorContent(for: self)
                params.status = .publish
                params.title = hasTitle ? editorContent.title : nil
                params.content = editorContent.content
            }

            try await create(params: params)

        case (.existingPost(let post, _), false):
            let params = settings.makeUpdateParameters(from: post, taxonomies: taxonomies)
            try await update(post: post, params: params)

        case (.existingPost(let post, _), true):
            var params = settings.makeUpdateParameters(from: post, taxonomies: taxonomies)
            params.status = .publish

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
        case .newPost(let existing):
            var params = existing
            params.status = publish ? .publish : .draft
            params.title = hasTitle ? content.title : nil
            params.content = content.content
            try await create(params: params)

        case .existingPost(let post, let pending):
            var params: PostUpdateParams
            if var pending {
                pending.tags = try await makeTermResolutionService(endpoint: .tags).resolveIDs(for: pending.tags)
                for taxonomy in taxonomies {
                    guard let slugTerms = pending.otherTerms[taxonomy.slug] else { continue }
                    pending.otherTerms[taxonomy.slug] = try await makeTermResolutionService(endpoint: taxonomy.endpoint)
                        .resolveIDs(for: slugTerms)
                }
                params = pending.makeUpdateParameters(from: post, taxonomies: taxonomies)
            } else {
                params = PostUpdateParams(meta: nil)
            }
            if publish {
                params.status = .publish
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
        let updatedPost = try await service.updatePost(endpointType: endpoint, postId: post.id, params: params)
        state = .existingPost(updatedPost)

        return updatedPost
    }

    /// Creates a new post and refreshes the local post list cache.
    @discardableResult
    private func create(params: PostCreateParams) async throws -> AnyPostWithEditContext {
        let endpoint = details.toPostEndpointType()
        let createdPost = try await service.createPost(endpointType: endpoint, params: params)
        state = .existingPost(createdPost)
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

extension PostCreateParams {
    /// Creates default parameters for a new post, equivalent to `Blog.createPost()`.
    static func defaultParams(from blog: Blog) -> PostCreateParams {
        var params = PostCreateParams(meta: nil)
        params.status = .draft

        if let categoryID = blog.settings?.defaultCategoryID,
           categoryID != PostCategory.uncategorized {
            params.categories = [TermId(categoryID.int64Value)]
        }

        params.format = blog.settings?.defaultPostFormat.flatMap { PostFormat.from(slug: $0) }

        if let userID = blog.userID {
            params.author = UserId(userID.int64Value)
        }

        return params
    }
}
