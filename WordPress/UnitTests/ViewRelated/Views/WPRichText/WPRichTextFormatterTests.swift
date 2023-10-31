import XCTest
@testable import WordPress


class WPRichTextFormatterTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }


    override func tearDown() {
        super.tearDown()

    }


    func testBlockquoteProcessor() {
        let processor = BlockquoteTagProcessor()

        var html = "<blockquote>Hi</blockquote>"
        var scanner = Scanner(string: html)
        var (result, _) = processor.process(scanner)
        var str = result as NSString
        XCTAssert(str.contains("<blockquote>\(WPRichTextFormatter.blockquoteIdentifier)Hi</blockquote>") )

        html = "<blockquote><p>Hi</p><p>Hi</p></blockquote>"
        scanner = Scanner(string: html)
        (result, _) = processor.process(scanner)
        str = result as NSString
        XCTAssert(str.contains("<blockquote><p>\(WPRichTextFormatter.blockquoteIdentifier)Hi</p><p>\(WPRichTextFormatter.blockquoteIdentifier)Hi</p></blockquote>"))
    }

    func testPreTagProcessor() {
        let processor = PreTagProcessor()

        var html = "<pre>\n\nHi\n\n</pre>"
        var scanner = Scanner(string: html)
        var (result, _) = processor.process(scanner)
        XCTAssert(result == html)

        html = "<pre>\nexample\nexample\n</pre>"
        scanner = Scanner(string: html)
        (result, _) = processor.process(scanner)

        let expectedResult = html + "<br>"
        XCTAssert(result == expectedResult)
    }

    func testImageTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "img", includesEndTag: false)

        let html = "<img src=\"http://example.com/example.png\" />"
        let scanner = Scanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str as String == attachment!.identifier)
    }


    func testVideoTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "video", includesEndTag: true)

        let html = "<video src=\"http://example.com/example.mov\" autoplay poster=\"image.png\"><track src=\"example.mp4\"></video>"
        let scanner = Scanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str as String == attachment!.identifier)
    }


    func testIFrameTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "iframe", includesEndTag: true)

        let html = "<iframe src=\"http://example.com/\"></iframe>"
        let scanner = Scanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str as String == attachment!.identifier)
    }


    func testAudioTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "audio", includesEndTag: true)

        let html = "<audio src=\"http://example.com/example.mp3\"></audio>"
        let scanner = Scanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str as String == attachment!.identifier)
    }


    func testFixBlockquoteIndentation() {
        let str = WPRichTextFormatter.blockquoteIdentifier + "Some text"
        var mattrStr = NSMutableAttributedString(string: str)

        let formatter = WPRichTextFormatter()
        mattrStr = formatter.fixBlockquoteIndentation(mattrStr)

        let pStyle = mattrStr.attribute(.paragraphStyle, at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: mattrStr.length)) as! NSParagraphStyle

        XCTAssert(pStyle.firstLineHeadIndent == formatter.blockquoteIndentation)
        XCTAssert(pStyle.headIndent == formatter.blockquoteIndentation)
    }


    func testAttributesFromTag() {

        let str = "<img src=\"http://example.com\" class=\"classname1 classname2\"alt='alt😀text' TITLE=\"Example\">"

        let processor = AttachmentTagProcessor(tagName: "img", includesEndTag: false)

        let attributes = processor.attributesFromTag(str)
        XCTAssert(attributes.count == 4)
        XCTAssert(attributes["src"] == "http://example.com")
        XCTAssert(attributes["class"] == "classname1 classname2")
        XCTAssert(attributes["alt"] == "alt😀text")
        XCTAssert(attributes["title"] == "Example")
    }

    func testThatParsingImageTagInsideVideoTagDoesntCrash() {
        let html = "<video><img /></video>"

        do {
            _ = try WPRichTextFormatter().attributedStringFromHTMLString(html, defaultDocumentAttributes: nil)
        }
        catch let err {
            XCTFail(err.localizedDescription)
        }
    }
}
