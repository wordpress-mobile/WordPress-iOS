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
        let str = "<p>test</p><p>test</p><img>"
        let styleStr = "<script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style><p>test</p><p><!-- wp:paragraph {\"fontSize\":\"large\"}--></p><p><!-- /wp:paragraph --></p>\n<img><p><!-- wp:self-closing-tag /--></p><script>alert();</script><style>body{color:#000;}</style>"
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

    func testRemoveGutenbergGalleryListMarkup() {
        let str = "Some text. <ul class=\"wp-block-gallery columns-3 is-cropped\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/IMG_1364.jpg\" alt=\"\" data-id=\"103\" data-link=\"https://example.com/img_1364/\" class=\"wp-image-103\" srcset=\"https://example.com/wp-content/uploads/2017/05/IMG_1364.jpg 2048w, https://example.com/wp-content/uploads/2017/05/IMG_1364-300x225.jpg 300w, https://example.com/wp-content/uploads/2017/05/IMG_1364-768x576.jpg 768w, https://example.com/wp-content/uploads/2017/05/IMG_1364-1024x768.jpg 1024w, https://example.com/wp-content/uploads/2017/05/IMG_1364-1200x900.jpg 1200w\" sizes=\"(max-width: 2048px) 100vw, 2048px\" /><figcaption>Plants<br></figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/IMG_1215.jpg\" alt=\"\" data-id=\"102\" data-link=\"https://example.com/img_1215/\" class=\"wp-image-102\" srcset=\"https://example.com/wp-content/uploads/2017/05/IMG_1215.jpg 2048w, https://example.com/wp-content/uploads/2017/05/IMG_1215-300x225.jpg 300w, https://example.com/wp-content/uploads/2017/05/IMG_1215-768x576.jpg 768w, https://example.com/wp-content/uploads/2017/05/IMG_1215-1024x768.jpg 1024w, https://example.com/wp-content/uploads/2017/05/IMG_1215-1200x900.jpg 1200w\" sizes=\"(max-width: 2048px) 100vw, 2048px\" /></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/img_5918.jpg\" alt=\"\" data-id=\"101\" data-link=\"https://example.com/img_5918-jpg/\" class=\"wp-image-101\" srcset=\"https://example.com/wp-content/uploads/2017/05/img_5918.jpg 1000w, https://example.com/wp-content/uploads/2017/05/img_5918-225x300.jpg 225w, https://example.com/wp-content/uploads/2017/05/img_5918-768x1024.jpg 768w\" sizes=\"(max-width: 1000px) 100vw, 1000px\" /></figure></li></ul> Some text."
        let sanitizedString = RichContentFormatter.formatGutenbergGallery(str) as NSString
        // Checks if the UL was removed.
        var range = sanitizedString.range(of: "block-gallery")
        XCTAssertTrue(range.location == NSNotFound)
        // Checks if the LI was removed
        range = sanitizedString.range(of: "blocks-gallery")
        XCTAssertTrue(range.location == NSNotFound)
        // Checks if the FIGCAPTION was kept.
        range = sanitizedString.range(of: "figcaption")
        XCTAssertTrue(range.location != NSNotFound)
    }

    func testFormatVideoTags() {
        let str1 = "<p>Some text.</p><video></video><p>Some text.</p>"
        let sanitizedStr1 = RichContentFormatter.formatVideoTags(str1) as NSString
        XCTAssert(sanitizedStr1.contains("controls"))

        let str2 = "<p>Some text.</p><video autoplay></video><p>Some text.</p>"
        let sanitizedStr2 = RichContentFormatter.formatVideoTags(str2) as NSString
        XCTAssert(sanitizedStr2.contains(" controls "))

        let str3 = "<p>Some text.</p><video controls></video><p>Some text.</p>"
        let sanitizedStr3 = RichContentFormatter.formatVideoTags(str3) as NSString
        XCTAssert(!sanitizedStr3.contains("controls controls"))
    }
}
