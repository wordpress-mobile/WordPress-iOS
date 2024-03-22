import UIKit
import XCTest

@testable import WordPress

class PostCompactCellGhostableTests: CoreDataTestCase {

    var postCell: PostCompactCell!
    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        super.setUp()
        postCell = postCellFromNib()
        postCell.ghostAnimationWillStart()
        try? featureFlags.override(RemoteFeatureFlag.syncPublishing, withValue: false)
    }

    override func tearDown() {
        try? featureFlags.override(RemoteFeatureFlag.syncPublishing, withValue: RemoteFeatureFlag.syncPublishing.originalValue)
        super.tearDown()
    }

    func testIsNotInteractive() {
        XCTAssertFalse(postCell.isUserInteractionEnabled)
    }

    func testShowGhost() {
        XCTAssertFalse(postCell.ghostView.isHidden)
        XCTAssertTrue(postCell.contentStackView.isHidden)
    }

    func testMenuButtonIsNotGhostable() {
        XCTAssertTrue(postCell.menuButton.isGhostableDisabled)
    }

    func testChangesMenuButtonOpacity() {
        XCTAssertEqual(postCell.menuButton.layer.opacity, 0.5)
    }

    func testIsInteractiveAfterAConfigure() {
        let post = PostBuilder(mainContext).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.isUserInteractionEnabled)
    }

    func testShowBadgesLabelAfterConfigure() {
        let post = PostBuilder(mainContext).build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.badgesLabel.isHidden)
    }

    func testHideGhostAfterConfigure() {
        let post = PostBuilder(mainContext).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.ghostView.isHidden)
        XCTAssertFalse(postCell.contentStackView.isHidden)
    }

    func testMenuButtonOpacityAfterConfigure() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.menuButton.layer.opacity, 1)
    }

    func testMenuButtonOpacityAfterConfigureWithPushingStatus() {
        let post = PostBuilder(mainContext).with(remoteStatus: .pushing).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.menuButton.layer.opacity, 0.3)
    }

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCompactCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}
