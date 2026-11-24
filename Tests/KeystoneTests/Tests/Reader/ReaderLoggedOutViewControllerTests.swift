import Testing
import UIKit

@testable import WordPress

@MainActor
struct ReaderLoggedOutViewControllerTests {
    /// `EmptyStateView` stores its `actions` builder and `UIHostingView` stores the
    /// resulting view, so a strong `self` in the builder is a cycle through the
    /// controller's own view hierarchy.
    @Test func deallocatesAfterLoadingView() {
        weak var controller: ReaderLoggedOutViewController?

        autoreleasepool {
            let viewController = ReaderLoggedOutViewController()
            controller = viewController
            viewController.loadViewIfNeeded()
        }

        #expect(controller == nil)
    }
}
