import XCTest
import Nimble

@testable import WordPress

class ReaderDetailViewControllerTests: XCTestCase {

    /// Given a post URL. returns a ReaderDetailViewController
    ///
    func testControllerWithURL() {
        let url = URL(string: "https://wpmobilep2.wordpress.com/post")!

        let controller = ReaderDetailViewController.controllerWithPostURL(url)

        expect(controller).to(beAKindOf(ReaderDetailViewController.self))
    }

    /// Starts the coordinator with the ReaderPost and call start in viewDidLoad
    ///
    func testControllerWithPostRendersPostContent() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let controller = ReaderDetailViewController.controllerWithPost(post)
        let coordinatorMock = ReaderDetailCoordinatorMock(view: controller)
        let originalCoordinator = controller.coordinator
        controller.coordinator = coordinatorMock
        _ = controller.view

        controller.viewDidLoad()

        expect(coordinatorMock.didCallStart).to(beTrue())
        expect(originalCoordinator?.post).to(equal(post))
    }

    /// Given a post and site ID, give it correctly to the coordinator
    ///
    func testControllerWithPostID() {
        let postID: NSNumber = 1
        let sideID: NSNumber = 2

        let controller = ReaderDetailViewController.controllerWithPostID(postID, siteID: sideID)

        expect(controller.coordinator?.postID).to(equal(1))
        expect(controller.coordinator?.siteID).to(equal(2))
        expect(controller.coordinator?.isFeed).to(beFalse())
    }

}

/// Builds a ReaderPost
///
class ReaderPostBuilder: PostBuilder {
    private let post: ReaderPost

    override init(_ context: NSManagedObjectContext = PostBuilder.setUpInMemoryManagedObjectContext(), blog: Blog? = nil) {
        post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: context) as! ReaderPost
    }

    func build() -> ReaderPost {
        post.blogURL = "https://wordpress.com"
        post.permaLink = "https://wordpress.com"
        return post
    }
}

private class ReaderDetailCoordinatorMock: ReaderDetailCoordinator {
    var didCallStart = false

    override func start() {
        didCallStart = true
    }
}
