import UIKit
import XCTest

@testable import WordPress

class PostCompactCellGhostableTests: XCTestCase {

    var postCell: PostCompactCell!

    override func setUp() {
        postCell = postCellFromNib()
        postCell.ghostAnimationWillStart()
    }

    func testIsNotInteractive() {
        XCTAssertFalse(postCell.isUserInteractionEnabled)
    }

    func testHideFeaturedImage() {
        XCTAssertTrue(postCell.featuredImageView.isHidden)
    }

    func testDisableDateAndBadgesSpacement() {
        XCTAssertFalse(postCell.labelsContainerTrailing.isActive)
    }

    func testTimestampLabel() {
        XCTAssertEqual(postCell.timestampLabel.text, "                                    ")
    }

    func testMenuButtonIsNotGhostable() {
        XCTAssertTrue(postCell.menuButton.isGhostableDisabled)
    }

    func testChangesMenuButtonOpacity() {
        XCTAssertEqual(postCell.menuButton.layer.opacity, 0.5)
    }

    func testTitleAndTimestampSpacing() {
        XCTAssertEqual(postCell.titleAndTimestampSpacing.constant, 8)
    }

    func testLabelsVerticalAlignment() {
        XCTAssertEqual(postCell.labelsCenter.constant, 0)
    }

    func testBadgesLabelIsHidden() {
        XCTAssertTrue(postCell.badgesLabel.isHidden)
    }

    func testIsInteractiveAfterAConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.isUserInteractionEnabled)
    }

    func testLabelsVerticalAlignmentAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.labelsCenter.constant, -1)
    }

    func testShowBadgesLabelAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.badgesLabel.isHidden)
    }

    func testTitleAndTimestampSpacingAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleAndTimestampSpacing.constant, 2)
    }

    func testMenuButtonOpacityAfterConfigure() {
        let post = PostBuilder().build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.menuButton.layer.opacity, 1)
    }

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}
