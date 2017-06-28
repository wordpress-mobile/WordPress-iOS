import XCTest
@testable import WordPress


// MARK: - CalypsoProcessorTests
//
class CalypsoProcessorTests: XCTestCase {

    let processor = CalypsoProcessor()

    /// Verifies that newlines get replaced with Line Break Elements
    ///
    func testNewlinesAreConvertedIntoBreakElements() {
        let input = "\nNewline \n Another \n New \n Line \n Here"
        let expected = "<br>Newline <br> Another <br> New <br> Line <br> Here"
        let output = processor.process(text: input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that paragraphs, separated by two consecutive newlines, are effectively wrapped into the
    /// HTML Paragraph Element.
    ///
    func testParagraphsAreConvertedIntoParagraphElements() {
        let input = "First paragraph\n Newline \n\nSecond Paragraph\n Newline \n Another line \n\n Third Paragraph"
        let expected = "<p>First paragraph<br> Newline </p><p>Second Paragraph<br> Newline <br> Another line </p><p> Third Paragraph</p>"
        let output = processor.process(text: input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that Preformatted Element's contents are not updated
    ///
    func testPreformattedTextIsEffectivelyPreserved() {
        let input = "<pre class='123'>Something\nHere\n\nAnd\nHere</pre>"
        let output = processor.process(text: input)

        XCTAssertEqual(output, input)
    }

    /// Verifies that any text surrounding a Pre Element gets it's newlines mapped to HTML Elements
    ///
    func testTextSurroundingPreformattedElementIsEffectivelyConverted() {
        let pre = "<pre class='123'>Something\nHere\n\nAnd\nHere</pre>"
        let input = pre + " LALALA \n LALA \n\n LA"
        let expected = "<p>" + pre + " LALALA <br> LALA </p><p> LA</p>"
        let output = processor.process(text: input)

        XCTAssertEqual(output, expected)
    }

    /// Verifies that multiple Pre Elements (if present) will keep their contents untouched.
    ///
    func testMultiplePreformattedElementsAreLeftUntouched() {
        let input = "<pre>First\n\nSecond</pre><pre>Third\nFourth</pre><pre>Fifth\n\nSixth\n</pre>"
        let output = processor.process(text: input)

        NSLog("Input: \(input)")
        NSLog("Output: \(output)")
        XCTAssertEqual(output, input)
    }
}
