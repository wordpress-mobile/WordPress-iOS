import Foundation

/// Extends `MediaRequestAuthenticator.MediaHost` so that we can easily
/// initialize it from a given `Blog`.
///
extension MediaHost {
    enum BlogError: Swift.Error {
        case baseInitializerError(error: Error, blog: Blog)
    }

    init(with blog: Blog, failure: (BlogError) -> ()) {
        self.init(isAccessibleThroughWPCom: blog.isAccessibleThroughWPCom(),
            isPrivate: blog.isPrivate(),
            isAtomic: blog.isAtomic(),
            siteID: blog.dotComID?.intValue,
            username: blog.usernameForSite,
            authToken: blog.authToken,
            failure: { error in
                // We just associate a blog with the underlying error for simpler debugging.
                failure(BlogError.baseInitializerError(
                    error: error,
                    blog: blog))
        })
   }
}
