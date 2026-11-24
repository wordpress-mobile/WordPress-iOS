import Testing
import UIKit

@testable import WordPress

@MainActor
struct NotificationsAuthorizationAlertTests {
    /// `AlertView` stores its `actions` builder and the builder's result becomes the
    /// host controller's `rootView`, so anything the builder captures strongly keeps
    /// the controller alive for the process lifetime.
    @Test func primerAlertControllerDeallocates() {
        weak var hostVC: UIViewController?

        autoreleasepool {
            let controller = NotificationsViewController.makeNotificationPrimerAlertController {}
            hostVC = controller
        }

        #expect(hostVC == nil)
    }
}
