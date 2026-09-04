import Foundation
import Testing

@testable import WordPressShared

struct RichContentFormatterTests {

    @Test func testRemoveInlineStyles() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<p style=\"background-color:#fff;\">test</p><p style=\"background-color:#fff;\">test</p>"
        let sanitizedStr = RichContentFormatter.removeInlineStyles(styleStr)
        #expect(str == sanitizedStr, "The inline styles were not removed.")
    }

    @Test func testRemoveForbiddenTags() {
        let str = "<p>test</p><p>test</p><img>"
        let styleStr =
            "<script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style><p>test</p><p><!-- wp:paragraph {\"fontSize\":\"large\"}--></p><p><!-- /wp:paragraph --></p>\n<img><p><!-- wp:self-closing-tag /--></p><script>alert();</script><style>body{color:#000;}</style>"
        let sanitizedStr = RichContentFormatter.removeForbiddenTags(styleStr)
        #expect(str == sanitizedStr, "The forbidden tags were not removed.")
    }

    @Test func testNormalizeParagraphs() {
        let str = "<p>test</p><pre>\n\ntest\n\n</pre><p>test</p>"
        let styleStr = "<div><p>test</p></div><pre>\n\ntest\n\n</pre>\n<p><div>test</div></p>\n"
        let sanitizedStr = RichContentFormatter.normalizeParagraphs(styleStr)
        #expect(str == sanitizedStr, "Not all paragraphs were normalized.")
    }

    @Test func testFilterNewLines() {
        let str = "<div><p>test</p></div><pre>\n\ntest\n\n</pre><p><div>test</div></p>"
        let styleStr = "<div><p>test</p></div><pre>\n\ntest\n\n</pre>\n<p><div>test</div></p>\n"
        let sanitizedStr = RichContentFormatter.filterNewLines(styleStr)
        #expect(str == sanitizedStr, "Not all paragraphs were normalized.")
    }

    @Test func testRemoveTrailingBRTags() {
        let str = "<p>test</p><br><p>test</p>"
        let styleStr = "<p>test</p><br><p>test</p><br><br> "
        let sanitizedStr = RichContentFormatter.removeTrailingBreakTags(styleStr)
        #expect(str == sanitizedStr, "The inline styles were not removed.")
    }

    @Test func testRemoveGutenbergGalleryListMarkup() {
        let str =
            "Some text. <ul class=\"wp-block-gallery columns-3 is-cropped\"><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/IMG_1364.jpg\" alt=\"\" data-id=\"103\" data-link=\"https://example.com/img_1364/\" class=\"wp-image-103\" srcset=\"https://example.com/wp-content/uploads/2017/05/IMG_1364.jpg 2048w, https://example.com/wp-content/uploads/2017/05/IMG_1364-300x225.jpg 300w, https://example.com/wp-content/uploads/2017/05/IMG_1364-768x576.jpg 768w, https://example.com/wp-content/uploads/2017/05/IMG_1364-1024x768.jpg 1024w, https://example.com/wp-content/uploads/2017/05/IMG_1364-1200x900.jpg 1200w\" sizes=\"(max-width: 2048px) 100vw, 2048px\" /><figcaption>Plants<br></figcaption></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/IMG_1215.jpg\" alt=\"\" data-id=\"102\" data-link=\"https://example.com/img_1215/\" class=\"wp-image-102\" srcset=\"https://example.com/wp-content/uploads/2017/05/IMG_1215.jpg 2048w, https://example.com/wp-content/uploads/2017/05/IMG_1215-300x225.jpg 300w, https://example.com/wp-content/uploads/2017/05/IMG_1215-768x576.jpg 768w, https://example.com/wp-content/uploads/2017/05/IMG_1215-1024x768.jpg 1024w, https://example.com/wp-content/uploads/2017/05/IMG_1215-1200x900.jpg 1200w\" sizes=\"(max-width: 2048px) 100vw, 2048px\" /></figure></li><li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/wp-content/uploads/2017/05/img_5918.jpg\" alt=\"\" data-id=\"101\" data-link=\"https://example.com/img_5918-jpg/\" class=\"wp-image-101\" srcset=\"https://example.com/wp-content/uploads/2017/05/img_5918.jpg 1000w, https://example.com/wp-content/uploads/2017/05/img_5918-225x300.jpg 225w, https://example.com/wp-content/uploads/2017/05/img_5918-768x1024.jpg 768w\" sizes=\"(max-width: 1000px) 100vw, 1000px\" /></figure></li></ul> Some text."
        let sanitizedString = RichContentFormatter.formatGutenbergGallery(str) as NSString
        // Checks if the UL was removed.
        var range = sanitizedString.range(of: "block-gallery")
        #expect(range.location == NSNotFound)
        // Checks if the LI was removed
        range = sanitizedString.range(of: "blocks-gallery")
        #expect(range.location == NSNotFound)
        // Checks if the FIGCAPTION was kept.
        range = sanitizedString.range(of: "figcaption")
        #expect(range.location != NSNotFound)
    }

    @Test func testFormatVideoTags() {
        let str1 = "<p>Some text.</p><video></video><p>Some text.</p>"
        let sanitizedStr1 = RichContentFormatter.formatVideoTags(str1) as NSString
        #expect(sanitizedStr1.contains("controls"))

        let str2 = "<p>Some text.</p><video autoplay></video><p>Some text.</p>"
        let sanitizedStr2 = RichContentFormatter.formatVideoTags(str2) as NSString
        #expect(sanitizedStr2.contains(" controls "))

        let str3 = "<p>Some text.</p><video controls></video><p>Some text.</p>"
        let sanitizedStr3 = RichContentFormatter.formatVideoTags(str3) as NSString
        #expect(!sanitizedStr3.contains("controls controls"))
    }

    // MARK: - Multi-code-unit input
    //
    // The bug sized each search range from the grapheme count (`content.count`) rather than the
    // UTF-16 length. A cluster that is one grapheme but several UTF-16 units — emoji, a ZWJ
    // sequence, a flag, a keycap, a skin-tone modifier, or a decomposed accent — therefore leaves
    // a token near the end of the string just past the range, so the search never reaches it.
    // Each test drives one such spot; the exact-output check also confirms the cluster is intact.

    @Test func testRegionalFlagStyleBlockSurvivesInTail() {
        // A <style> block after a flag emoji is stripped; the neighbouring <b> stays.
        let out = RichContentFormatter.removeForbiddenTags("🇺🇸<b>hi</b><style>zz</style>")
        #expect(out == "🇺🇸<b>hi</b>")
    }

    @Test func testZWJFamilyScriptTagSurvivesInTail() {
        // A <script> after a family emoji — one grapheme but 11 UTF-16 units, the widest gap here.
        let out = RichContentFormatter.removeForbiddenTags("👨‍👩‍👧‍👦<script>x</script>")
        #expect(out == "👨‍👩‍👧‍👦")
    }

    @Test func testKeycapGutenbergCommentSurvivesInTail() {
        // A Gutenberg block comment after a keycap emoji is stripped.
        let out = RichContentFormatter.removeForbiddenTags("1️⃣<p><!-- wp:paragraph --></p>")
        #expect(out == "1️⃣")
    }

    @Test func testSkinToneDivStartNotConvertedInTail() {
        // <div> is converted to <p> even after a skin-tone emoji.
        let out = RichContentFormatter.normalizeParagraphs("👍🏽<div>")
        #expect(out == "👍🏽<p>")
    }

    @Test func testNFDCombiningDivEndNotConvertedInTail() {
        // </div> is converted to </p> after a decomposed "é" (e + a combining accent). A composed
        // "é" is a single UTF-16 unit and would not reach past the range, so the decomposition matters.
        let out = RichContentFormatter.normalizeParagraphs("cafe\u{301}</div>")
        #expect(out == "cafe\u{301}</p>")
    }

    @Test func testNormalizeParagraphsMergesTrailingDoubleOpenParagraph() {
        // A redundant <p><p> is collapsed to a single <p>.
        let out = RichContentFormatter.normalizeParagraphs("😀<p><p>")
        #expect(out == "😀<p>")
    }

    @Test func testNormalizeParagraphsMergesTrailingDoubleCloseParagraph() {
        // A redundant </p></p> is collapsed to a single </p>.
        let out = RichContentFormatter.normalizeParagraphs("😀</p></p>")
        #expect(out == "😀</p>")
    }

    @Test func testFilterNewLinesNoPreFallbackRemovesNewlinePastWideCluster() {
        // A newline outside any <pre> block is removed.
        let out = RichContentFormatter.filterNewLines("👨‍👩‍👧‍👦\nA")
        #expect(out == "👨‍👩‍👧‍👦A")
    }

    @Test func testFilterNewLinesElseBranchPreservesTrailingNewlineAfterWideCluster() {
        // With a <pre> block present, a newline that follows it (outside the block) is still removed.
        let out = RichContentFormatter.filterNewLines("<pre>\n</pre>👨‍👩‍👧‍👦\nZ")
        #expect(out == "<pre>\n</pre>👨‍👩‍👧‍👦Z")
    }

    @Test func testFilterNewLinesMultiPreInverseRanges() {
        // Across several <pre> blocks: newlines inside them are kept, newlines outside are removed.
        let out = RichContentFormatter.filterNewLines("👨‍👩‍👧‍👦\n<pre>a\nb</pre>\n😀\n<pre>c\nd</pre>\n🇺🇸\n")
        #expect(out == "👨‍👩‍👧‍👦<pre>a\nb</pre>😀<pre>c\nd</pre>🇺🇸")
    }

    @Test func testZWJFamilyStyleAttrSurvivesInTruncatedTail() {
        // An inline style attribute after a family emoji is stripped.
        let out = RichContentFormatter.removeInlineStyles("👨‍👩‍👧‍👦<div style=\"x\">")
        #expect(out == "👨‍👩‍👧‍👦<div>")
    }

    @Test func testZWJFamilyTrailingBreakSurvivesAndCutsCleanly() {
        // A trailing <br> after a family emoji is removed, and the emoji before it stays intact.
        let out = RichContentFormatter.removeTrailingBreakTags("👨‍👩‍👧‍👦text<br>")
        #expect(out == "👨‍👩‍👧‍👦text")
    }

    @Test func testTrailingBreakOnlyFinalRemovedEmojiIntact() {
        // Only the trailing <br> is removed; an earlier <br> in the middle of the text stays.
        let out = RichContentFormatter.removeTrailingBreakTags("😀<br>text<br>")
        #expect(out == "😀<br>text")
    }

    @Test func testForbiddenCleanMultibyteUnchanged() {
        // Content with no tags to strip passes through unchanged.
        let out = RichContentFormatter.removeForbiddenTags("Hello 👨‍👩‍👧‍👦 world 😀!")
        #expect(out == "Hello 👨‍👩‍👧‍👦 world 😀!")
    }

    // MARK: - Boundary + selectivity (not new fix sites)

    @Test func testBoundaryStraddleOffByOne() {
        // One emoji makes the range exactly one UTF-16 unit short, and the token's closing ">"
        // is exactly that dropped unit — pins the off-by-one where the wide-gap cases have slack.
        let out = RichContentFormatter.removeForbiddenTags("text<script>😀</script>")
        #expect(out == "text")
    }

    @Test func testStripsTagInRangeAndInTailNotJustEverything() {
        // The first style attribute is always in range; the ZWJ family pushes the second into the
        // truncated tail. The fix strips both; the bug strips only the first — so the range, not a
        // blanket "strip everything", decides which tags go.
        let out = RichContentFormatter.removeInlineStyles("<a style=\"one\">👨‍👩‍👧‍👦<b style=\"two\">")
        #expect(out == "<a>👨‍👩‍👧‍👦<b>")
    }

    // MARK: - parseValueForAttribute robustness

    @Test func testParseValueForAttributeReturnsValue() {
        let value = RichContentFormatter.parseValueForAttribute("src", inElement: "<img src=\"http://x/a.jpg\">")
        #expect(value == "http://x/a.jpg")
    }

    @Test func testParseValueForAttributeMissingClosingQuoteReturnsEmpty() {
        // Opening quote but no closing quote: the closing-quote search returns NSNotFound, so the
        // range length would underflow to a huge value and crash substring(with:). Return "" instead.
        let value = RichContentFormatter.parseValueForAttribute("src", inElement: "<img src=\"http://x/a.jpg>")
        #expect(value.isEmpty)
    }

    @Test func testParseValueForAttributeAbsentReturnsEmpty() {
        let value = RichContentFormatter.parseValueForAttribute("src", inElement: "<img alt=\"x\">")
        #expect(value.isEmpty)
    }
}
