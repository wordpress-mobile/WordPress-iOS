import UIKit
import XCTest

@testable import WordPress

private typealias Titles = PostActionSheet.Titles

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
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Move to Draft", "Move to Trash"], options)
    }

    func testLocallyPublishedPostShowsCancelAutoUploadOption() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().with(remoteStatus: .failed).confirmedAutoUpload().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual([Titles.cancel, Titles.cancelAutoUpload, Titles.draft, Titles.trash], options)
    }

    func testDraftedPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().drafted().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Publish Now", "Move to Trash"], options)
    }

    func testScheduledPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().scheduled().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Move to Trash"], options)
    }

    func testTrashedPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().trashed().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Delete Permanently"], options)
    }

    func testPublishedPostOptionsWithView() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "View", "Stats", "Move to Draft", "Move to Trash"], options)
    }

    func testCallDelegateWhenStatsTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Stats", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleStats)
    }

    func testCallDelegateWhenMoveToDraftTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Move to Draft", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleDraft)
    }

    func testCallDelegateWhenDeletePermanentlyTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().trashed().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Delete Permanently", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenMoveToTrashTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Move to Trash", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenViewTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)
        tap("View", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func testCallsDelegateWhenCancelAutoUploadIsTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder().published().with(remoteStatus: .failed).confirmedAutoUpload().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)
        tap(Titles.cancelAutoUpload, in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallCancelAutoUpload)
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
    private(set) var didCallHandleStats = false
    private(set) var didCallHandleDraft = false
    private(set) var didCallHandleTrashPost = false
    private(set) var didCallEdit = false
    private(set) var didCallView = false
    private(set) var didCallRetry = false
    private(set) var didCallCancelAutoUpload = false

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
        didCallCancelAutoUpload = true
    }
}
