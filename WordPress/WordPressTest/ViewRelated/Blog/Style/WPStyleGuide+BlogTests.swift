import XCTest
import WordPressShared.WPStyleGuide
@testable import WordPress

class WPStyleGuide_BlogTests: XCTestCase {
    var testCell: UITableViewCell!

    override func setUp() {
        testCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: nil)
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        testCell = nil
    }

    func testConfigureTableViewBlogCellSetsFont() {
        WPStyleGuide.configureTableViewBlogCell(testCell)
        XCTAssertEqual(WPStyleGuide.subtitleFont(), testCell.detailTextLabel!.font)
    }

    func testConfigureTableViewBlogCellSetsBackgroundColor() {
        WPStyleGuide.configureTableViewBlogCell(testCell)
        XCTAssertEqual(UIColor.listForeground, testCell.backgroundColor)
    }
}
