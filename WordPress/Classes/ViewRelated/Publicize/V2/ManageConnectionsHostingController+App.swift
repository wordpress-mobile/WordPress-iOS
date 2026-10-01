import Foundation
import UIKit
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

    /// Sharing screen for My Site and the Stats post-sharing action.
    ///
    /// A successful ``make(for:)`` returns the Social connections controller.
    /// Non-publicize blogs, and publicize blogs whose service cannot be built
    /// for a structural reason, use sharing-button settings. `JetpackSocialFactory`
    /// owns the token and site-ID checks; this method does not repeat them.
    ///
    /// Returns `nil` only when construction fails for an existing account that
    /// cannot reach WordPress.com. Reading ``Blog/isAccessibleThroughWPCom``
    /// posts `.wpAccountRequiresShowingSigninForWPComFixingAuthToken`, which the
    /// global sign-in observer already turns into auth recovery. Callers must
    /// not present another sign-in screen. `nil` is that recovery request, not
    /// an unexplained failure.
    @MainActor
    static func sharingDestination(for blog: Blog) -> UIViewController? {
        guard blog.supports(.publicize) else {
            return SharingButtonsViewController(blog: blog)
        }

        if let controller = make(for: blog) {
            return controller
        }

        if blog.account != nil, !blog.isAccessibleThroughWPCom {
            return nil
        }

        return SharingButtonsViewController(blog: blog)
    }
}
