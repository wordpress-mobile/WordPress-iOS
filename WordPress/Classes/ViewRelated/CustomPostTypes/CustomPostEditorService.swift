import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

class CustomPostEditorService {
    private(set) var post: AnyPostWithEditContext
    let details: PostTypeDetailsWithEditContext
    let client: WordPressClient

    init(post: AnyPostWithEditContext, details: PostTypeDetailsWithEditContext, client: WordPressClient) {
        self.post = post
        self.details = details
        self.client = client
    }

    /// Updates the post and refreshes the local post list cache.
    @discardableResult
    func update(params: PostUpdateParams) async throws -> AnyPostWithEditContext {
        let endpoint = details.toPostEndpointType()
        let updatedPost = try await client.api.posts
            .update(postEndpointType: endpoint, postId: post.id, params: params)
            .data
        self.post = updatedPost

        // Refresh post in to keep the post list up-to-date
        do {
            try await client.service.posts().refreshPost(
                postId: updatedPost.id, endpointType: endpoint
            )
        } catch {
            Loggers.app.error("Failed to refresh post list cache: \(error)")
        }

        return updatedPost
    }
}
