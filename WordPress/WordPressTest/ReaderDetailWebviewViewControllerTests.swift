import XCTest
import Nimble

@testable import WordPress

class ReaderDetailWebviewViewControllerTests: XCTestCase {

    /// Given a post and site ID, returns a ReaderDetailWebviewViewController
    ///
    func testControllerWithPostID() {
        let postID: NSNumber = 1
        let sideID: NSNumber = 2

        let controller = ReaderDetailWebviewViewController.controllerWithPostID(postID, siteID: sideID)

        expect(controller).to(beAKindOf(ReaderDetailWebviewViewController.self))
    }

    /// Given a post URL. returns a ReaderDetailWebviewViewController
    ///
    func testControllerWithURL() {
        let url = URL(string: "https://wpmobilep2.wordpress.com/post")!

        let controller = ReaderDetailWebviewViewController.controllerWithPostURL(url)

        expect(controller).to(beAKindOf(ReaderDetailWebviewViewController.self))
    }

    /// Given a ReaderPost sets the VC post to the given
    ///
    func testControllerWithPostRendersPostContent() {
        let post: ReaderPost = ReaderPostBuilder().build()

        let controller = ReaderDetailWebviewViewController.controllerWithPost(post)

        expect(controller.post).to(equal(post))
    }

}

/// Builds a ReaderPost
///
private class ReaderPostBuilder: PostBuilder {
    private let post: ReaderPost

    override init(_ context: NSManagedObjectContext = PostBuilder.setUpInMemoryManagedObjectContext(), blog: Blog? = nil) {
        post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: context) as! ReaderPost
    }

    func build() -> ReaderPost {
        return post
    }
}
