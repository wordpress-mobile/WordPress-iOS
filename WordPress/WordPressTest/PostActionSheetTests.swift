import UIKit
import XCTest

@testable import WordPress

class PostActionSheetTests: XCTestCase {

    private var postActionSheet: PostActionSheet!
    private var viewControllerMock: UIViewControllerMock!
    private var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    private var view: UIView!

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
        XCTAssertEqual(["Cancel", "Publish Now", "Move to Trash"], options)
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

    func testPublishedPostOptionsWithView() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view, showViewOption: true)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "View", "Stats", "Move to Draft", "Move to Trash"], options)
    }

    func testCallDelegateWhenStatsTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        tap("Stats", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleStats)
    }

    func testCallDelegateWhenMoveToDraftTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        tap("Move to Draft", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleDraft)
    }

    func testCallDelegateWhenDeletePermanentlyTapped() {
        let post = PostBuilder().trashed().build()

        postActionSheet.show(for: post, from: view)
        tap("Delete Permanently", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenMoveToTrashTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view)
        tap("Move to Trash", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenViewTapped() {
        let post = PostBuilder().published().build()

        postActionSheet.show(for: post, from: view, showViewOption: true)
        tap("View", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func tap(_ label: String, in alertController: UIAlertController?) {
        typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

        if let action = alertController?.actions.first(where: { $0.title == label }) {
            let block = action.value(forKey: "handler")
            let blockPtr = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained(block as AnyObject).toOpaque())
            let handler = unsafeBitCast(blockPtr, to: AlertHandler.self)
            handler(action)
        }
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

class InteractivePostViewDelegateMock: InteractivePostViewDelegate {
    var didCallHandleStats = false
    var didCallHandleDraft = false
    var didCallHandleTrashPost = false
    var didCallEdit = false
    var didCallView = false
    var didCallRetry = false

    func stats(for post: AbstractPost) {
        didCallHandleStats = true
    }

    func draft(_ post: AbstractPost) {
        didCallHandleDraft = true
    }

    func trash(_ post: AbstractPost) {
        didCallHandleTrashPost = true
    }

    func edit(_ post: AbstractPost) {
        didCallEdit = true
    }

    func view(_ post: AbstractPost) {
        didCallView = true
    }

    func publish(_ post: AbstractPost) {

    }

    func restore(_ post: AbstractPost) {

    }

    func retry(_ post: AbstractPost) {
        didCallRetry = true
    }

    func cancelAutoUpload(_ post: AbstractPost) {
        // noop
    }
}
