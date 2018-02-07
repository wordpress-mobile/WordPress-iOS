import XCTest
import WordPressUIKit.WPStyleGuide

class WPStyleGuide_BlogTests: XCTestCase {
    var testCell: UITableViewCell!

    override func setUp() {
        testCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
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

    func testConfigureTableViewBlogCellSetsDetailTextLabelColor() {
        WPStyleGuide.configureTableViewBlogCell(testCell)
        XCTAssertEqual(WPStyleGuide.greyDarken10(), testCell.detailTextLabel!.textColor)
    }

    func testConfigureTableViewBlogCellSetsBackgroundColor() {
        WPStyleGuide.configureTableViewBlogCell(testCell)
        XCTAssertEqual(UIColor.white, testCell.backgroundColor)
    }
}
