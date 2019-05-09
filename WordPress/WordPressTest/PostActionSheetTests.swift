import UIKit
import XCTest

@testable import WordPress

class PostActionSheetTests: XCTestCase {

    var postActionSheet: PostActionSheet!
    var viewControllerMock: UIViewControllerMock!
    var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    var view: UIView!

    override func setUp() {
        viewControllerMock = UIViewControllerMock()
        interactivePostViewDelegateMock = InteractivePostViewDelegateMock()
        view = UIView()
        postActionSheet = PostActionSheet(viewController: viewControllerMock, interactivePostViewDelegate: interactivePostViewDelegateMock)
    }

    func testPublishedPostOptions() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Move to Draft", "Move to Trash"], options)
    }

    func testDraftedPostOptions() {
        let post = PostBuilder().drafted().build()

        postActionSheet.show(for: post, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Move to Trash"], options)
    }

    func testScheduledPostOptions() {
        let post = PostBuilder().scheduled().build()

        postActionSheet.show(for: post, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Move to Trash"], options)
    }

    func testTrashedPostOptions() {
        let post = PostBuilder().trashed().build()

        postActionSheet.show(for: post, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Delete Permanently"], options)
    }

    func testCallDelegateWhenStatsTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        viewControllerMock.viewControllerPresented?.tap("Stats")

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleStats)
    }

    func testCallDelegateWhenMoveToDraftTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        viewControllerMock.viewControllerPresented?.tap("Move to Draft")

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleDraft)
    }

    func testCallDelegateWhenDeletePermanentlyTapped() {
        let post = PostBuilder().trashed().build()

        postActionSheet.show(for: post, from: view)
        viewControllerMock.viewControllerPresented?.tap("Delete Permanently")

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenMoveToTrashTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        viewControllerMock.viewControllerPresented?.tap("Move to Trash")

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testActionSheetSourceView() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)

        XCTAssertEqual(viewControllerMock.viewControllerPresented?.popoverPresentationController?.sourceView, view)
    }

    func testActionSheetSourceRect() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)

        XCTAssertEqual(viewControllerMock.viewControllerPresented?.popoverPresentationController?.sourceRect, view.bounds)
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

class InteractivePostViewDelegateMock: NSObject, InteractivePostViewDelegate {

    var didCallHandleStats = false
    var didCallHandleDraft = false
    var didCallHandleTrashPost = false

    func handleStats(for post: AbstractPost) {
        didCallHandleStats = true
    }

    func handleDraftPost(_ post: AbstractPost) {
        didCallHandleDraft = true
    }

    func handleTrashPost(_ post: AbstractPost) {
        didCallHandleTrashPost = true
    }
}
