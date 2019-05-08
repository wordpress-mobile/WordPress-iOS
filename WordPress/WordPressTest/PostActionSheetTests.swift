import UIKit
import XCTest

@testable import WordPress

class PostActionSheetTests: XCTestCase {

    var postActionSheet: PostActionSheet!
    var viewControllerMock: UIViewControllerMock!

    override func setUp() {
        viewControllerMock = UIViewControllerMock()
        postActionSheet = PostActionSheet(viewController: viewControllerMock)
    }

    func testPublishedPostOptions() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Move to drafts", "Move to trash"], options)
    }

    func testDraftedPostOptions() {
        let post = PostBuilder().drafted().build()

        postActionSheet.show(for: post)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Move to drafts", "Move to trash"], options)
    }

    func testScheduledPostOptions() {
        let post = PostBuilder().scheduled().build()

        postActionSheet.show(for: post)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to drafts", "Move to trash"], options)
    }

    func testTrashedPostOptions() {
        let post = PostBuilder().trashed().build()

        postActionSheet.show(for: post)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to drafts", "Delete permanently"], options)
    }

}

class UIViewControllerMock: UIViewController {

    var didCallPresent = false
    var viewControllerPresented: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresent = true
        viewControllerPresented = viewControllerToPresent as? UIAlertController
    }
}
