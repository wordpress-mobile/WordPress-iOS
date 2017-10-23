import XCTest
@testable import WordPress


// MARK: - CalypsoProcessorInTests
//
class CalypsoProcessorInTests: XCTestCase {

    let processor = CalypsoProcessorIn()

    /// Verifies that newlines get replaced with Line Break Elements
    ///
    func testNewlinesAreConvertedIntoBreakElements() {
        let input = "\nNewline \n Another \n New \n Line \n Here"
        let expected = "<p>\nNewline<br />\n Another<br />\n New<br />\n Line<br />\n Here</p>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that paragraphs, separated by two consecutive newlines, are effectively wrapped into the     /// HTML Paragraph Element.
    ///
    func testParagraphsAreConvertedIntoParagraphElements() {
        let input = "First paragraph\n Newline \n\nSecond Paragraph\n Newline \n Another line \n\n Third Paragraph"
        let expected = "<p>First paragraph<br />\n Newline </p>\n<p>Second Paragraph<br />\n Newline<br />\n Another line </p>\n<p> Third Paragraph</p>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that Preformatted Element's contents are not updated
    ///
    func testPreformattedTextIsEffectivelyPreserved() {
        let input = "<pre class='123'>Something\nHere\n\nAnd\nHere</pre>"
        let expected = "<pre class=\'123\'>Something\nHere\n\nAnd\nHere</pre>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that any text surrounding a Pre Element gets it's newlines mapped to HTML Elements
    ///
    func testTextSurroundingPreformattedElementIsEffectivelyConverted() {
        let pre = "<pre class='123'>Something\nHere\n\nAnd\nHere</pre>"
        let input = pre + " LALALA \n LALA \n\n LA"
        let expected = pre + "\n<p> LALALA<br />\n LALA </p>\n<p> LA</p>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that multiple Pre Elements (if present) will keep their contents untouched.
    ///
    func testMultiplePreformattedElementsAreLeftUntouched() {
        let input = "<pre>First\n\nSecond</pre><pre>Third\nFourth</pre><pre>Fifth\n\nSixth\n</pre>"
        let expected = "<pre>First\n\nSecond</pre>\n<pre>Third\nFourth</pre>\n<pre>Fifth\n\nSixth\n</pre>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that Ordered Lists (with nested levels) will keep their contents untouched.
    ///
    func testOrderedListsWithNestedEntitiesAreLeftUntouched() {
        let input = "<ol>\n<li>hello\nbye</li>\n<li><ol><li>WAT\nWAT</li></ol></li></ol>"
        let expected = "<ol>\n<li>hello<br />\nbye</li>\n<li>\n<ol>\n<li>WAT<br />\nWAT</li>\n</ol>\n</li>\n</ol>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that Unordered Lists (with nested levels) will keep their contents untouched.
    ///
    func testUnorderedListsWithNestedEntitiesAreLeftUntouched() {
        let input = "<ul>\n<li>hello\nbye</li>\n<li><ul><li>WAT\nWAT</li></ul></li></ul>"
        let expected = "<ul>\n<li>hello<br />\nbye</li>\n<li>\n<ul>\n<li>WAT<br />\nWAT</li>\n</ul>\n</li>\n</ul>\n"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that Pre + UL + OL tags escaping algorithm is case insensitive, and it's 
    /// contents are left untouched, even when in uppercase.
    ///
    func testSantizationIsCaseInsensitiveAndEscapedUppercaseTagsAreLeftUntouched() {
        let input = "here<UL>\n<LI>hello\nbye</LI>\n" +
            "<LI><UL><LI>WAT\nWAT</LI></UL></LI></UL>there" +
            "<PRE>\n</PRE>testing" +
            "<OL><LI>ORDERED\n</LI></OL>"

        let expected = "<p>here</p>\n<UL>\n<LI>hello<br />\nbye</LI>\n" +
            "<LI>\n<UL>\n<LI>WAT<br />\nWAT</LI>\n</UL>\n</LI>\n</UL>\n<p>there</p>\n" +
            "<PRE>\n</PRE>\n<p>testing</p>\n" +
            "<OL>\n<LI>ORDERED\n</LI>\n</OL>\n"

        let output = processor.process(input)
        XCTAssertEqual(output, expected)
    }
}
