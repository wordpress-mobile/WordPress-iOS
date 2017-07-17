import XCTest
@testable import WordPressShared

class RichContentFormatterTests: XCTestCase {

    func testRemoveInlineStyles() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<p style=\"background-color:#fff;\">test</p><p style=\"background-color:#fff;\">test</p>"
        let sanitizedStr = RichContentFormatter.removeInlineStyles(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The inline styles were not removed.")
    }


    func testRemoveForbiddenTags() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style>"
        let sanitizedStr = RichContentFormatter.removeForbiddenTags(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The forbidden tags were not removed.")
    }


    func testNormalizeParagraphs() {
        let str = "<p>test</p><pre>\n\ntest\n\n</pre><p>test</p>"
        let styleStr = "<div><p>test</p></div><pre>\n\ntest\n\n</pre>\n<p><div>test</div></p>\n"
        let sanitizedStr = RichContentFormatter.normalizeParagraphs(styleStr)
        XCTAssertTrue(str == sanitizedStr, "Not all paragraphs were normalized.")
    }


    func testFilterNewLines() {
        let str = "<div><p>test</p></div><pre>\n\ntest\n\n</pre><p><div>test</div></p>"
        let styleStr = "<div><p>test</p></div><pre>\n\ntest\n\n</pre>\n<p><div>test</div></p>\n"
        let sanitizedStr = RichContentFormatter.filterNewLines(styleStr)
        XCTAssertTrue(str == sanitizedStr, "Not all paragraphs were normalized.")
    }

    func testResizeGalleryImageURLsForContentEmptyString() {
        XCTAssertTrue("" == RichContentFormatter.resizeGalleryImageURL("", isPrivateSite: false))
    }


    func testRemoveTrailingBRTags() {
        let str = "<p>test</p><br><p>test</p>"
        let styleStr = "<p>test</p><br><p>test</p><br><br> "
        let sanitizedStr = RichContentFormatter.removeTrailingBreakTags(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The inline styles were not removed.")
    }
}
