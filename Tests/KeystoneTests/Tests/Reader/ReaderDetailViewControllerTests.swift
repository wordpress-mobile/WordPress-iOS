import XCTest

@testable import WordPress
@testable import WordPressData

class ReaderDetailViewControllerTests: CoreDataTestCase {

    /// Given a post URL. returns a ReaderDetailViewController
    ///
    func testControllerWithURL() {
        let url = URL(string: "https://wpmobilep2.wordpress.com/post")!

        let controller = ReaderDetailViewController.controllerWithPostURL(url)

        XCTAssertTrue(controller is ReaderDetailViewController)
    }

    /// Starts the coordinator with the ReaderPost and call start in viewDidLoad
    ///
    func testControllerWithPostRendersPostContent() {
        let post: ReaderPost = ReaderPostBuilder(mainContext).build()
        let controller = ReaderDetailViewController.controllerWithPost(post)
        let coordinatorMock = ReaderDetailCoordinatorMock(view: controller)
        let originalCoordinator = controller.coordinator
        controller.coordinator = coordinatorMock
        _ = controller.view

        controller.viewDidLoad()

        XCTAssertTrue(coordinatorMock.didCallStart)
        XCTAssertEqual(originalCoordinator?.post, post)
    }

    /// Given a post and site ID, give it correctly to the coordinator
    ///
    func testControllerWithPostID() {
        let postID: NSNumber = 1
        let sideID: NSNumber = 2

        let controller = ReaderDetailViewController.controllerWithPostID(postID, siteID: sideID)

        XCTAssertEqual(controller.coordinator?.postID, 1)
        XCTAssertEqual(controller.coordinator?.siteID, 2)
        XCTAssertEqual(controller.coordinator?.isFeed, false)
    }

}

/// Builds a ReaderPost

private class ReaderDetailCoordinatorMock: ReaderDetailCoordinator {
    var didCallStart = false

    override func start() {
        didCallStart = true
    }
}
