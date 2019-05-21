import UIKit
import XCTest

@testable import WordPress

class PostCompactCellTests: XCTestCase {

    var postCell: PostCompactCell!

    override func setUp() {
        postCell = postCellFromNib()
    }

    private func postCellFromNib() -> PostCompactCell {
        let bundle = Bundle(for: PostCell.self)
        guard let postCell = bundle.loadNibNamed("PostCompactCell", owner: nil)?.first as? PostCompactCell else {
            fatalError("PostCompactCell does not exist")
        }

        return postCell
    }

}
