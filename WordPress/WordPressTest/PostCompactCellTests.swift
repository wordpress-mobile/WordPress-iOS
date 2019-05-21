import UIKit
import XCTest

@testable import WordPress

class PostCompactCellTests: XCTestCase {

    var postCell: PostCompactCell!

    override func setUp() {
        postCell = postCellFromNib()
    }

    func testCellHeight() {
        XCTAssertEqual(PostCompactCell.height, 60)
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder().withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImageView.isHidden)
        XCTAssertTrue(postCell.labelsContainerTrailing.isActive)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImageView.isHidden)
        XCTAssertFalse(postCell.labelsContainerTrailing.isActive)
    }

    func testShowPostTitle() {
        let post = PostBuilder().with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowDate() {
        let post = PostBuilder().with(dateCreated: Date()).drafted().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.timestampLabel.text, "just now")
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

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCompactCell does not exist")
        }

        return postCell
    }

}
