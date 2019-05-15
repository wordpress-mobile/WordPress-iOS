import UIKit
import XCTest

@testable import WordPress

class PostCellTests: XCTestCase {

    var postCell: PostCell!
    var interactivePostViewDelegateMock: InteractivePostViewDelegateMock!
    var postActionSheetDelegateMock: PostActionSheetDelegateMock!

    override func setUp() {
        postCell = postCellFromNib()
        interactivePostViewDelegateMock = InteractivePostViewDelegateMock()
        postActionSheetDelegateMock = PostActionSheetDelegateMock()
        postCell.setInteractionDelegate(interactivePostViewDelegateMock)
        postCell.setActionSheetDelegate(postActionSheetDelegateMock)
    }

    func testIsAUITableViewCell() {
        XCTAssertNotNil(postCell as UITableViewCell)
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder().withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImage.isHidden)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImage.isHidden)
    }

    func testShowPostTitle() {
        let post = PostBuilder().with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowPostSnippet() {
        let post = PostBuilder().with(snippet: "Post content").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.snippetLabel.text, "Post content")
    }

    func testShowDate() {
        let post = PostBuilder().with(dateCreated: Date()).drafted().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.dateLabel.text, "just now")
    }

    func testShowAuthor() {
        let post = PostBuilder().with(author: "John Doe").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.authorLabel.text, " · John Doe")
    }

    func testShowStickyLabelWhenPostIsSticky() {
        let post = PostBuilder().is(sticked: true).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.stickyLabel.isHidden)
    }

    func testHideStickyLabelWhenPostIsntSticky() {
        let post = PostBuilder().is(sticked: false).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.stickyLabel.isHidden)
    }

    func testShowSeparatorWhenPostHasStatusAndItIsSticky() {
        let post = PostBuilder()
                    .with(remoteStatus: .sync).private()
                    .is(sticked: true).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.statusAndStickySeparator.isHidden)
    }

    func testHideSeparatorWhenHasOnlyStickyLabel() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .is(sticked: true).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.statusAndStickySeparator.isHidden)
    }

    func testHideSeparatorWhenHasOnlyStatusLabel() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .private().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.statusAndStickySeparator.isHidden)
    }

    func testShowPrivateLabelWhenPostIsPrivate() {
        let post = PostBuilder().with(remoteStatus: .sync).private().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "Private")
    }

    func testDoNotShowTrashedLabel() {
        let post = PostBuilder().with(remoteStatus: .sync).trashed().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testDoNotShowScheduledLabel() {
        let post = PostBuilder().with(remoteStatus: .sync).scheduled().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.statusLabel.text, "")
    }

    func testHideHideStatusView() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.statusView.isHidden)
    }

    func testShowStatusView() {
        let post = PostBuilder()
            .with(remoteStatus: .failed)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.statusView.isHidden)
    }

    func testShowProgressView() {
        let post = PostBuilder()
            .with(remoteStatus: .pushing)
            .published().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.progressView.isHidden)
    }

    func testHideProgressView() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .published().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.progressView.isHidden)
    }

    func testEditAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.edit()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallEdit)
    }

    func testViewAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.view()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallView)
    }

    func testMoreAction() {
        let button = UIButton()
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.more(button)

        XCTAssertEqual(postActionSheetDelegateMock.calledWithPost, post)
        XCTAssertEqual(postActionSheetDelegateMock.calledWithView, button)
    }

    func testRetryAction() {
        let post = PostBuilder().published().build()
        postCell.configure(with: post)

        postCell.retry()

        XCTAssertTrue(interactivePostViewDelegateMock.didCallRetry)
    }

    func testShowRetryButtonAndHideViewButton() {
        let post = PostBuilder().with(remoteStatus: .failed).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.retryButton.isHidden)
        XCTAssertTrue(postCell.viewButton.isHidden)
    }

    func testHideAuthor() {
        let post = PostBuilder().with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.isAuthorHidden = true

        XCTAssertTrue(postCell.authorLabel.isHidden)
    }

    func testDoesNotHideAuthor() {
        let post = PostBuilder().with(author: "John Doe").build()
        postCell.configure(with: post)

        postCell.isAuthorHidden = false

        XCTAssertFalse(postCell.authorLabel.isHidden)
    }

    private func postCellFromNib() -> PostCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCell", owner: nil)?.first as? PostCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}

class PostActionSheetDelegateMock: PostActionSheetDelegate {
    var calledWithPost: AbstractPost?
    var calledWithView: UIView?

    func showActionSheet(_ post: AbstractPost, from view: UIView) {
        calledWithPost = post
        calledWithView = view
    }
}
