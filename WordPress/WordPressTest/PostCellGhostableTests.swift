import UIKit
import XCTest

@testable import WordPress

class PostCellGhostableTests: XCTestCase {

    var postCell: PostCell!

    override func setUp() {
        postCell = postCellFromNib()
        postCell.ghostAnimationWillStart()
    }

    func testHideFeaturedImage() {
        XCTAssertTrue(postCell.featuredImageStackView.isHidden)
    }

    func testEmptiesTitleLabel() {
        XCTAssertEqual(postCell.titleLabel?.text, " ")
    }

    func testShowSnippetLabel() {
        XCTAssertFalse(postCell.snippetLabel.isHidden)
    }

    func testDateLabelPlaceholder() {
        XCTAssertEqual(postCell.dateLabel?.text, "                                    ")
    }

    func testHideAuthorLabel() {
        XCTAssertTrue(postCell.authorLabel.isHidden)
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
        let margin: CGFloat = WPDeviceIdentification.isiPad() ? 20 : 16

        XCTAssertEqual(postCell.topPadding.constant, margin)
    }

    func testVerticalContentSpacing() {
        XCTAssertEqual(postCell.contentStackView.spacing, 0)
    }

    func testSpaceBetweenTitleAndSnippet() {
        XCTAssertEqual(postCell.titleAndSnippetView.spacing, 16)
    }

    func testTopAndBottomOfTitleAndSnippet() {
        XCTAssertEqual(postCell.titleAndSnippetView.layoutMargins.top, 0)
        XCTAssertEqual(postCell.titleAndSnippetView.layoutMargins.bottom, 8)
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

    func testTitleAndSnippetSpacingAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleAndSnippetView.spacing, 3)
    }

    func testActionBarOpacityAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.actionBarView.layer.opacity, 1)
    }

    private func postCellFromNib() -> PostCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCell", owner: nil)?.first as? PostCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}
