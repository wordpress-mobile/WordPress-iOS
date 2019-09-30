import UIKit
import XCTest

@testable import WordPress

class PostCardCellGhostableTests: XCTestCase {

    var postCell: PostCardCell!

    override func setUp() {
        postCell = postCellFromNib()
        postCell.ghostAnimationWillStart()
    }

    func testHideFeaturedImage() {
        XCTAssertTrue(postCell.featuredImageStackView.isHidden)
    }

    func testShowGhostView() {
        XCTAssertFalse(postCell.ghostStackView.isHidden)
    }

    func testShowSnippetLabel() {
        XCTAssertFalse(postCell.snippetLabel.isHidden)
    }

    func testHideStatusView() {
        XCTAssertTrue(postCell.statusView.isHidden)
    }

    func testHideProgressView() {
        XCTAssertTrue(postCell.progressView.isHidden)
    }

    func testChangesActionBarOpacity() {
        XCTAssertEqual(postCell.actionBarView.layer.opacity, 0.5)
    }

    func testIsNotInteractive() {
        XCTAssertFalse(postCell.isUserInteractionEnabled)
    }

    func testTopPadding() {
        XCTAssertEqual(postCell.topPadding.constant, 16)
    }

    func testActionBarIsNotGhostable() {
        XCTAssertTrue(postCell.actionBarView.isGhostableDisabled)
    }

    func testUpperBorderIsNotGhostable() {
        XCTAssertTrue(postCell.upperBorder.isGhostableDisabled)
    }

    func testBottomBorderIsNotGhostable() {
        XCTAssertTrue(postCell.bottomBorder.isGhostableDisabled)
    }

    func testIsInteractiveAfterAConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.isUserInteractionEnabled)
    }

    func testVerticalContentSpacingAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.contentStackView.spacing, 8)
    }

    func testActionBarOpacityAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.actionBarView.layer.opacity, 1)
    }

    func testHideGhostView() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.ghostStackView.isHidden)
    }

    private func postCellFromNib() -> PostCardCell {
        let bundle = Bundle(for: PostCardCell.self)
        guard let postCell = bundle.loadNibNamed("PostCardCell", owner: nil)?.first as? PostCardCell else {
            fatalError("PostCardCell does not exist")
        }

        return postCell
    }

}
