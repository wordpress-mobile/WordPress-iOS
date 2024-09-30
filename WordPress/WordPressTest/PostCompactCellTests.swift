import UIKit
import XCTest

@testable import WordPress

class PostCompactCellTests: CoreDataTestCase {

    var postCell: PostCompactCell!

    override func setUp() {
        postCell = postCellFromNib()
    }

    func testShowImageWhenAvailable() {
        let post = PostBuilder(mainContext).withImage().build()

        postCell.configure(with: post)

        XCTAssertFalse(postCell.featuredImageView.isHidden)
    }

    func testHideImageWhenNotAvailable() {
        let post = PostBuilder(mainContext).build()

        postCell.configure(with: post)

        XCTAssertTrue(postCell.featuredImageView.isHidden)
    }

    func testShowPostTitle() {
        let post = PostBuilder(mainContext).with(title: "Foo bar").build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.titleLabel.text, "Foo bar")
    }

    func testShowDate() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync)
            .with(dateCreated: Date()).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.timestampLabel.text, "now")
    }

    func testStatusAndBadgeLabels() {
        let post = PostBuilder(mainContext).with(remoteStatus: .sync)
            .with(dateCreated: Date()).is(sticked: true).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.badgesLabel.text, "Sticky")
    }

    func testShowBadgesWhenNotEmpty() {
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .sync)
            .build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.badgesLabel.text, "")
        XCTAssertTrue(postCell.badgesLabel.isHidden)
    }

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCompactCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCompactCell does not exist")
        }

        return postCell
    }

}
