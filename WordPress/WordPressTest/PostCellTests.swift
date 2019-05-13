import UIKit
import XCTest

@testable import WordPress

class PostCellTests: XCTestCase {

    var postCell: PostCell!

    override func setUp() {
        postCell = postCellFromNib()
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
        let post = PostBuilder().with(dateCreated: Date()).build()

        postCell.configure(with: post)

        XCTAssertEqual(postCell.dateLabel.text, "just now")
    }

    private func postCellFromNib() -> PostCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCell", owner: nil)?.first as? PostCell else {
            fatalError("PostCell does not exist")
        }

        return postCell
    }

}
