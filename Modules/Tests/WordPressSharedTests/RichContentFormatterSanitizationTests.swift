import Foundation
import Testing

@testable import WordPressShared

/// Behavioural coverage for `RichContentFormatter`'s platform-independent text
/// transformations — the regex-driven sanitisation that runs over untrusted
/// remote post and comment HTML.
///
/// These methods live in `WordPressShared`, so this suite runs under `swift test`
/// on macOS with no simulator.
@Suite("RichContentFormatter sanitization")
struct RichContentFormatterSanitizationTests {

    // MARK: - removeForbiddenTags

    @Suite("removeForbiddenTags")
    struct RemoveForbiddenTags {
        @Test(
            "strips script, style, and Gutenberg-comment paragraphs",
            arguments: [
                // Basic script/style removal.
                ("<script>alert(1)</script>Hello", "Hello"),
                ("<style>body{color:#000}</style>Hello", "Hello"),
                // Case-insensitive.
                ("<SCRIPT>alert(1)</SCRIPT>Hello", "Hello"),
                ("<STYLE type=\"text/css\">a{}</STYLE>Hello", "Hello"),
                // Attributes on the opening tag.
                ("<script src=\"evil.js\">x</script>Hi", "Hi"),
                // Newlines inside the element body.
                ("<script>\n  alert(1)\n</script>Hi", "Hi"),
                // Multiple occurrences.
                ("a<script>1</script>b<script>2</script>c", "abc"),
                ("a<style>1</style>b<style>2</style>c", "abc"),
                // Gutenberg block comments wrapped in <p>, with and without trailing newline.
                ("<p><!-- wp:paragraph --></p>\nHi", "Hi"),
                ("<p><!-- /wp:paragraph --></p>Hi", "Hi"),
                ("<p><!-- wp:self-closing-tag /--></p>Hi", "Hi"),
                // An unclosed forbidden tag is stripped through the end of the input.
                ("<script>alert(1)", ""),
                ("Hello <script>alert(1)", "Hello "),
                ("<style>body{}", ""),
                // Non-BMP prefix must not shrink the UTF-16 search range.
                ("😀😀😀😀😀<script>alert(1)</script>", "😀😀😀😀😀"),
                // No-ops.
                ("<p>plain paragraph</p>", "<p>plain paragraph</p>"),
                ("", "")
            ]
        )
        func strips(input: String, expected: String) {
            #expect(RichContentFormatter.removeForbiddenTags(input) == expected)
        }
    }

    // MARK: - removeInlineStyles

    @Suite("removeInlineStyles")
    struct RemoveInlineStyles {
        @Test(
            "strips double-quoted style attributes and the whitespace before them",
            arguments: [
                ("<p style=\"color:red\">x</p>", "<p>x</p>"),
                ("<p STYLE=\"color:red\">x</p>", "<p>x</p>"),
                ("<p style=\"\">x</p>", "<p>x</p>"),
                // Leading whitespace is consumed with the attribute.
                ("<a href=\"x\" style=\"color:red\">y</a>", "<a href=\"x\">y</a>"),
                // Multiple styled elements.
                ("<p style=\"a\">1</p><p style=\"b\">2</p>", "<p>1</p><p>2</p>"),
                // Single-quoted styles are stripped too, leaving other attributes intact.
                ("<p style='color:red'>x</p>", "<p>x</p>"),
                ("<a style='a' title=\"t\">y</a>", "<a title=\"t\">y</a>"),
                // Attribute names ending in `style` are NOT corrupted (left boundary).
                ("<img data-style=\"x\" src=\"y\">", "<img data-style=\"x\" src=\"y\">"),
                ("<div data-mce-style='z'>t</div>", "<div data-mce-style='z'>t</div>"),
                // Non-BMP prefix must not shrink the UTF-16 search range.
                ("😀<p style=\"color:red\">t</p>", "😀<p>t</p>"),
                // No-ops.
                ("<p>no style here</p>", "<p>no style here</p>"),
                ("", "")
            ]
        )
        func strips(input: String, expected: String) {
            #expect(RichContentFormatter.removeInlineStyles(input) == expected)
        }
    }

    // MARK: - normalizeParagraphs

    @Suite("normalizeParagraphs")
    struct NormalizeParagraphs {
        @Test(
            "converts DIVs to Ps, collapses redundant Ps, and drops non-PRE newlines",
            arguments: [
                // Anchor case from the original suite.
                (
                    "<div><p>test</p></div><pre>\n\ntest\n\n</pre>\n<p><div>test</div></p>\n",
                    "<p>test</p><pre>\n\ntest\n\n</pre><p>test</p>"
                ),
                // Simple div -> p.
                ("<div>x</div>", "<p>x</p>"),
                // Div with attributes.
                ("<div class=\"wp-block\">x</div>", "<p>x</p>"),
                // Already-normal paragraphs are left alone.
                ("<p>a</p><p>b</p>", "<p>a</p><p>b</p>"),
                // Non-BMP prefix must not desync the div->p conversion (balanced tags).
                ("😀😀😀😀😀<div>x</div>", "😀😀😀😀😀<p>x</p>"),
                ("", "")
            ]
        )
        func normalizes(input: String, expected: String) {
            #expect(RichContentFormatter.normalizeParagraphs(input) == expected)
        }
    }

    // MARK: - filterNewLines

    @Suite("filterNewLines")
    struct FilterNewLines {
        @Test(
            "removes newlines except inside <pre> blocks",
            arguments: [
                // No PRE: every newline goes.
                ("a\nb\nc", "abc"),
                ("\n\n\n", ""),
                // Newlines inside PRE are preserved; those outside are removed.
                ("<pre>a\nb</pre>", "<pre>a\nb</pre>"),
                ("x\n<pre>a\nb</pre>\ny", "x<pre>a\nb</pre>y"),
                // Multiple PRE blocks.
                ("<pre>1\n2</pre>\n<pre>3\n4</pre>\n", "<pre>1\n2</pre><pre>3\n4</pre>"),
                ("", "")
            ]
        )
        func filters(input: String, expected: String) {
            #expect(RichContentFormatter.filterNewLines(input) == expected)
        }

        @Test("drops a newline after a non-BMP character (UTF-16-correct NSRange)")
        func dropsNewlineAfterNonBMP() {
            // "😀" is one Character but two UTF-16 code units; the range must use the UTF-16
            // length or the trailing newline falls outside it and is left in place.
            #expect(RichContentFormatter.filterNewLines("ab😀\n") == "ab😀")
        }
    }

    // MARK: - removeTrailingBreakTags

    @Suite("removeTrailingBreakTags")
    struct RemoveTrailingBreakTags {
        @Test(
            "trims trailing <br> runs (and surrounding whitespace) but keeps interior ones",
            arguments: [
                // Anchor case.
                ("<p>test</p><br><p>test</p><br><br> ", "<p>test</p><br><p>test</p>"),
                // Single trailing break, various spellings.
                ("text<br>", "text"),
                ("text<br/>", "text"),
                ("text<br />", "text"),
                ("text<BR>", "text"),
                // Runs.
                ("text<br><br><br>", "text"),
                ("<br><br>", ""),
                // Interior break is preserved.
                ("a<br>b", "a<br>b"),
                // Non-BMP prefix: trailing <br> still trimmed, and no out-of-bounds crash.
                ("😀<br>", "😀"),
                ("😀😀😀😀😀<br>", "😀😀😀😀😀"),
                // Leading/trailing whitespace is trimmed even with no break.
                ("  spaced  ", "spaced"),
                ("no breaks", "no breaks"),
                ("", "")
            ]
        )
        func trims(input: String, expected: String) {
            #expect(RichContentFormatter.removeTrailingBreakTags(input) == expected)
        }
    }

    // MARK: - formatVideoTags

    @Suite("formatVideoTags")
    struct FormatVideoTags {
        @Test(
            "adds a controls attribute only when absent",
            arguments: [
                ("<p>x</p><video></video><p>y</p>", "<p>x</p><video controls></video><p>y</p>"),
                ("<video autoplay></video>", "<video controls autoplay></video>"),
                // Already has controls -> untouched.
                ("<video controls></video>", "<video controls></video>"),
                // `controls` inside an attribute value/name is not the controls attribute.
                (
                    "<video poster=\"https://x/controls.jpg\"></video>",
                    "<video controls poster=\"https://x/controls.jpg\"></video>"
                ),
                ("<video class=\"my-controls\"></video>", "<video controls class=\"my-controls\"></video>"),
                ("<video controlslist=\"nodownload\"></video>", "<video controls controlslist=\"nodownload\"></video>"),
                // Existing CONTROLS (case-insensitive) is not duplicated.
                ("<video CONTROLS></video>", "<video CONTROLS></video>"),
                // Must not over-match a different element.
                ("<videoxyz></videoxyz>", "<videoxyz></videoxyz>"),
                // No video -> untouched.
                ("<p>no video</p>", "<p>no video</p>"),
                ("", "")
            ]
        )
        func addsControls(input: String, expected: String) {
            #expect(RichContentFormatter.formatVideoTags(input) == expected)
        }

        @Test("preserves the opening tag's original casing when inserting controls")
        func preservesOpeningTagCasing() {
            #expect(RichContentFormatter.formatVideoTags("<VIDEO></VIDEO>") == "<VIDEO controls></VIDEO>")
        }
    }

    // MARK: - parseValueForAttribute

    @Suite("parseValueForAttribute")
    struct ParseValueForAttribute {
        @Test(
            "returns the double-quoted value of an attribute, or empty when absent",
            arguments: [
                ("src", "<img src=\"http://example.com/a.jpg\">", "http://example.com/a.jpg"),
                (
                    "data-orig-file", "<img data-orig-file=\"http://example.com/o.jpg\" src=\"s\">",
                    "http://example.com/o.jpg"
                ),
                // Missing attribute.
                ("href", "<img src=\"x\">", ""),
                // Present but empty.
                ("src", "<img src=\"\">", ""),
                // First match wins.
                ("src", "<img src=\"a\" src=\"b\">", "a")
            ]
        )
        func parses(attribute: String, element: String, expected: String) {
            #expect(RichContentFormatter.parseValueForAttribute(attribute, inElement: element) == expected)
        }

        @Test("Regression: an unterminated attribute quote returns empty instead of crashing")
        func unterminatedQuoteReturnsEmpty() {
            // Previously `ending.location == NSNotFound` was fed into `substringWithRange:`,
            // throwing NSInvalidArgumentException. Reachable from adversarial gallery HTML via
            // `resizeGalleryImageURL`. Now guarded to return "".
            #expect(RichContentFormatter.parseValueForAttribute("src", inElement: "<img src=\"unterminated>").isEmpty)
        }

        @Test("does not match an attribute name as a substring of another attribute")
        func doesNotMatchSubstringAttributeName() {
            // "rc" must not match inside "src", nor "orig-file" inside "data-orig-file".
            #expect(RichContentFormatter.parseValueForAttribute("rc", inElement: "<img src=\"x\">").isEmpty)
            #expect(
                RichContentFormatter.parseValueForAttribute("orig-file", inElement: "<img data-orig-file=\"y\">")
                    .isEmpty
            )
        }
    }

    // MARK: - formatGutenbergGallery

    @Suite("formatGutenbergGallery")
    struct FormatGutenbergGallery {
        @Test(
            "leaves non-gallery content untouched",
            arguments: [
                "<p>hello</p>",
                "<ul><li>plain list</li></ul>",
                ""
            ]
        )
        func noOp(input: String) {
            #expect(RichContentFormatter.formatGutenbergGallery(input) == input)
        }

        @Test("removes gallery UL/LI markup while keeping the figures inside")
        func stripsGalleryMarkupKeepsFigures() {
            let input =
                "Before. <ul class=\"wp-block-gallery columns-3 is-cropped\">"
                + "<li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/1.jpg\" />"
                + "<figcaption>One</figcaption></figure></li>"
                + "<li class=\"blocks-gallery-item\"><figure><img src=\"https://example.com/2.jpg\" /></figure></li>"
                + "</ul> After."
            let output = RichContentFormatter.formatGutenbergGallery(input) as NSString

            #expect(output.range(of: "block-gallery").location == NSNotFound)
            #expect(output.range(of: "blocks-gallery").location == NSNotFound)
            #expect(output.range(of: "<figure>").location != NSNotFound)
            #expect(output.range(of: "figcaption").location != NSNotFound)
            #expect(output.range(of: "https://example.com/1.jpg").location != NSNotFound)
            #expect(output.range(of: "https://example.com/2.jpg").location != NSNotFound)
        }
    }
}
