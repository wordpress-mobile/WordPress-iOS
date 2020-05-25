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

}
