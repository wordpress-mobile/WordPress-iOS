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
        var scanner = NSScanner(string: html)
        var (result, _) = processor.process(scanner)
        var str = result as NSString
        XCTAssert(str.containsString("<blockquote>\(WPRichTextFormatter.blockquoteIdentifier)Hi</blockquote>") )

        html = "<blockquote><p>Hi</p><p>Hi</p></blockquote>"
        scanner = NSScanner(string: html)
        (result, _) = processor.process(scanner)
        str = result as NSString
        XCTAssert(str.containsString("<blockquote><p>\(WPRichTextFormatter.blockquoteIdentifier)Hi</p><p>\(WPRichTextFormatter.blockquoteIdentifier)Hi</p></blockquote>"))
    }


    func testImageTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "img", includesEndTag: false)

        let html = "<img src=\"http://example.com/example.png\" />"
        let scanner = NSScanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str == attachment!.identifier)
    }


    func testVideoTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "video", includesEndTag: true)

        let html = "<video src=\"http://example.com/example.mov\" autoplay poster=\"image.png\"><track src=\"example.mp4\"></video>"
        let scanner = NSScanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str == attachment!.identifier)
    }


    func testIFrameTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "iframe", includesEndTag: true)

        let html = "<iframe src=\"http://example.com/\"></iframe>"
        let scanner = NSScanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str == attachment!.identifier)
    }


    func testAudioTagProcessor() {
        let processor = AttachmentTagProcessor(tagName: "audio", includesEndTag: true)

        let html = "<audio src=\"http://example.com/example.mp3\"></audio>"
        let scanner = NSScanner(string: html)
        let (result, attachment) = processor.process(scanner)
        let str = result as NSString
        XCTAssert(str == attachment!.identifier)
    }


    func testFixBlockquoteIndentation() {
        let str = WPRichTextFormatter.blockquoteIdentifier + "Some text"
        var mattrStr = NSMutableAttributedString(string: str)

        let formatter = WPRichTextFormatter()
        mattrStr = formatter.fixBlockquoteIndentation(mattrStr)

        let pStyle = mattrStr.attribute(NSParagraphStyleAttributeName, atIndex: 0, longestEffectiveRange: nil, inRange: NSRange(location: 0, length: mattrStr.length)) as! NSParagraphStyle

        XCTAssert(pStyle.firstLineHeadIndent == formatter.blockquoteIndentation)
        XCTAssert(pStyle.headIndent == formatter.blockquoteIndentation)
    }

}
