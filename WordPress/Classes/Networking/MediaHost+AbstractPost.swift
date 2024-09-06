import Foundation

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `AbstractPost`.
///
extension MediaHost {
    enum AbstractPostError: Swift.Error {
        case baseInitializerError(error: BlogError)
    }

    init(with post: AbstractPost, failure: (AbstractPostError) -> ()) {
        let postId = TaggedManagedObjectID(post)
        self.init(
            with: post.blog,
            failure: { error in
                // We just associate a post with the underlying error for simpler debugging.
                failure(AbstractPostError.baseInitializerError(error: error))
            }
        )
   }
}
