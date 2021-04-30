import UIKit
import XCTest

@testable import WordPress

class PostCompactCellTests: XCTestCase {

    var postCell: PostCompactCell!

    override func setUp() {
        postCell = postCellFromNib()
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder().withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImageView.isHidden)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImageView.isHidden)
    }

    func testShowPostTitle() {
        let post = PostBuilder().with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowDate() {
        let post = PostBuilder().with(remoteStatus: .sync)
            .with(dateCreated: Date()).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.timestampLabel.text, "now")
    }

    func testMoreAction() {
        let postActionSheetDelegateMock = PostActionSheetDelegateMock()
        let post = PostBuilder().published().build()
        postCell.configure(with: post)
        postCell.setActionSheetDelegate(postActionSheetDelegateMock)

        postCell.menuButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(postActionSheetDelegateMock.calledWithPost, post)
        XCTAssertEqual(postActionSheetDelegateMock.calledWithView, postCell.menuButton)
    }

    func testStatusAndBadgeLabels() {
        let post = PostBuilder().with(remoteStatus: .sync)
            .with(dateCreated: Date()).is(sticked: true).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.badgesLabel.text, "Sticky")
    }

    func testHideBadgesWhenEmpty() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.badgesLabel.text, "Uploading post...")
        XCTAssertFalse(postCell.badgesLabel.isHidden)
    }

    func testShowBadgesWhenNotEmpty() {
        let post = PostBuilder()
            .with(remoteStatus: .sync)
            .build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.badgesLabel.text, "")
        XCTAssertTrue(postCell.badgesLabel.isHidden)
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

    func testShowsWarningMessageForFailedPublishedPosts() {
        // Given
        let post = PostBuilder().published().with(remoteStatus: .failed).confirmedAutoUpload().build()

        // When
        postCell.configure(with: post)

        // Then
        XCTAssertEqual(postCell.badgesLabel.text, i18n("We'll publish the post when your device is back online."))
        XCTAssertEqual(postCell.badgesLabel.textColor, UIColor.warning)
    }

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCompactCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCompactCell does not exist")
        }

        return postCell
    }

}
