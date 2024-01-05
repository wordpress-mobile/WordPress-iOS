import UIKit
import XCTest

@testable import WordPress

private typealias Titles = PostActionSheet.Titles

class PostActionSheetTests: CoreDataTestCase {

    private var postActionSheet: PostActionSheet!
    private var viewControllerMock: UIViewControllerMock!
    private var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    private var view: UIView!

    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        viewControllerMock = UIViewControllerMock()
        interactivePostViewDelegateMock = InteractivePostViewDelegateMock()
        view = UIView()
        postActionSheet = PostActionSheet(viewController: viewControllerMock, interactivePostViewDelegate: interactivePostViewDelegateMock)
    }

    func testPublishedPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Stats", "Share", "Duplicate", "Move to Draft", "Copy Link", "Move to Trash"], options)
    }

    func testLocallyPublishedPostShowsCancelAutoUploadOption() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().with(remoteStatus: .failed).confirmedAutoUpload().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual([Titles.cancel, Titles.cancelAutoUpload, Titles.duplicate, Titles.draft, Titles.copyLink, Titles.trash], options)
    }

    func testDraftedPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).drafted().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Publish Now", "Duplicate", "Copy Link", "Move to Trash"], options)
    }

    func testScheduledPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).scheduled().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Copy Link", "Move to Trash"], options)
    }

    func testTrashedPostOptions() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).trashed().build())

        postActionSheet.show(for: viewModel, from: view)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "Move to Draft", "Delete Permanently"], options)
    }

    func testPublishedPostOptionsWithView() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)

        let options = viewControllerMock.viewControllerPresented?.actions.compactMap { $0.title }
        XCTAssertEqual(["Cancel", "View", "Stats", "Share", "Duplicate", "Move to Draft", "Copy Link", "Move to Trash"], options)
    }

    func testCallDelegateWhenStatsTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Stats", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleStats)
    }

    func testCallDelegateWhenDuplicateTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Duplicate", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleDuplicate)
    }

    func testCallDelegateWhenShareTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().withRemote().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Share", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallShare)
    }

    func testCallDelegateWhenMoveToDraftTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Move to Draft", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleDraft)
    }

    func testCallDelegateWhenDeletePermanentlyTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).trashed().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Delete Permanently", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenCopyLink() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Copy Link", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallCopyLink)
    }

    func testCallDelegateWhenMoveToTrashTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().build())

        postActionSheet.show(for: viewModel, from: view)
        tap("Move to Trash", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallHandleTrashPost)
    }

    func testCallDelegateWhenViewTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)
        tap("View", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func testCallDelegateWhenBlazeTapped() throws {
        try featureFlags.override(RemoteFeatureFlag.blaze, withValue: true)

        let blog = BlogBuilder(mainContext)
            .canBlaze()
            .build()

        let post = PostBuilder(mainContext, blog: blog)
            .published()
            .build()

        let viewModel = PostCardStatusViewModel(post: post, isBlazeFlagEnabled: true)

        postActionSheet.show(for: viewModel, from: view)
        tap("Promote with Blaze", in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallBlaze)
    }

    func testCallsDelegateWhenCancelAutoUploadIsTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).published().with(remoteStatus: .failed).confirmedAutoUpload().build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)
        tap(Titles.cancelAutoUpload, in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallCancelAutoUpload)
    }

    func testCallsDelegateWhenRetryIsTapped() {
        let viewModel = PostCardStatusViewModel(post: PostBuilder(mainContext).with(remoteStatus: .failed).with(autoUploadAttemptsCount: 5).build())

        postActionSheet.show(for: viewModel, from: view, isCompactOrSearching: true)
        tap(Titles.retry, in: viewControllerMock.viewControllerPresented)

        XCTAssertTrue(interactivePostViewDelegateMock.didCallRetry)
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

private class UIViewControllerMock: UIViewController {

    var didCallPresent = false
    var viewControllerPresented: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresent = true
        viewControllerPresented = viewControllerToPresent as? UIAlertController
    }
}

class InteractivePostViewDelegateMock: InteractivePostViewDelegate {
    private(set) var didCallHandleStats = false
    private(set) var didCallHandleDuplicate = false
    private(set) var didCallHandleDraft = false
    private(set) var didCallHandleTrashPost = false
    private(set) var didCallEdit = false
    private(set) var didCallView = false
    private(set) var didCallRetry = false
    private(set) var didCallCancelAutoUpload = false
    private(set) var didCallShare = false
    private(set) var didCallCopyLink = false
    private(set) var didCallBlaze = false

    func stats(for post: AbstractPost) {
        didCallHandleStats = true
    }

    func duplicate(_ post: AbstractPost) {
        didCallHandleDuplicate = true
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

    func retry(_ post: AbstractPost) {
        didCallRetry = true
    }

    func cancelAutoUpload(_ post: AbstractPost) {
        didCallCancelAutoUpload = true
    }

    func share(_ post: AbstractPost, fromView view: UIView) {
        didCallShare = true
    }

    func copyLink(_ post: AbstractPost) {
        didCallCopyLink = true
    }

    func blaze(_ post: AbstractPost) {
        didCallBlaze = true
    }
}
