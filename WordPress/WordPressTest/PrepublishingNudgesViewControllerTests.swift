import XCTest
import Nimble

@testable import WordPress

class PrepublishingNudgesViewControllerTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        /// We need that in order to initialize the Authenticator, otherwise this test crashes
        /// This is because we're using the NUXButton. Ideally, that component should be extracted
        WordPressAuthenticationManager().initializeWordPressAuthenticator()
    }

    /// Call the completion block when the "Publish" button is pressed
    ///
    func testCallCompletionBlockWhenButtonTapped() {
        let post = PostBuilder().build()
        var returnedPost: AbstractPost?
        let prepublishingViewController = PrepublishingViewController(post: post) { post in
            returnedPost = post
        }
        _ = UINavigationController(rootViewController: prepublishingViewController)
        prepublishingViewController.viewDidLoad()

        prepublishingViewController.publishButton.sendActions(for: .touchUpInside)

        expect(returnedPost).toEventually(equal(post))
    }

}
