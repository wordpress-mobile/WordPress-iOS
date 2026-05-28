import Foundation
import JetpackSocial
import WordPressData

extension ManageConnectionsHostingController {
    /// Returns `nil` gracefully when the blog is not a WP.com-connected
    /// Jetpack Social site.
    static func make(for blog: Blog) -> ManageConnectionsHostingController? {
        guard let service = JetpackSocialFactory.shared.connectionsService(for: blog) else {
            return nil
        }
        return ManageConnectionsHostingController(
            connectionsService: service,
            authenticator: BlogSocialOAuthAuthenticator(blog: blog)
        )
    }
}
