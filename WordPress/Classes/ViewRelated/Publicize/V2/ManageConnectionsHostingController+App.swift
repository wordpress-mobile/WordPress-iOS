import Foundation
import JetpackSocial
import WordPressCore
import WordPressData

extension ManageConnectionsHostingController {
    /// Returns `nil` gracefully when the blog cannot be represented as a
    /// `WordPressSite` or has no WP.com account linked.
    static func make(for blog: Blog) -> ManageConnectionsHostingController? {
        guard let site = try? WordPressSite(blog: blog),
            let service = JetpackSocialFactory.shared.connectionsService(for: site)
        else {
            return nil
        }
        return ManageConnectionsHostingController(
            connectionsService: service,
            authenticator: BlogSocialOAuthAuthenticator(blog: blog)
        )
    }
}
