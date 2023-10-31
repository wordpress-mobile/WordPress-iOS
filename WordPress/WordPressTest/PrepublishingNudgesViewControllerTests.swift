import XCTest
import Nimble

@testable import WordPress

class PrepublishingNudgesViewControllerTests: CoreDataTestCase {

    override class func setUp() {
        super.setUp()

        let windowManager = WindowManager(window: UIWindow())

        /// We need that in order to initialize the Authenticator, otherwise this test crashes
        /// This is because we're using the NUXButton. Ideally, that component should be extracted
        WordPressAuthenticationManager(
            windowManager: windowManager,
            remoteFeaturesStore: RemoteFeatureFlagStore()
        ).initializeWordPressAuthenticator()
    }

    /// Call the completion block when the "Publish" button is pressed
    ///
    func testCallCompletionBlockWhenButtonTapped() {
        var post = PostBuilder(mainContext).build()
        var returnedPost: AbstractPost?
        let prepublishingViewController = PrepublishingViewController(post: post, identifiers: [.schedule, .visibility, .tags, .categories]) { result in
            switch result {
            case .completed(let completedPost):
                if let completedPost = completedPost as? Post {
                    post = completedPost
                }
            case .dismissed:
                ()
            }
            returnedPost = post
        }
        _ = UINavigationController(rootViewController: prepublishingViewController)
        prepublishingViewController.viewDidLoad()

        prepublishingViewController.publishButton.sendActions(for: .touchUpInside)

        expect(returnedPost).toEventually(equal(post))
    }

}
