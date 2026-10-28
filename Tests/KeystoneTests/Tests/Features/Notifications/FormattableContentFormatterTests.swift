import XCTest
@testable import WordPress
@testable import FormattableContentKit
import Foundation

final class FormattableContentFormatterTests: XCTestCase {
    private var subject: FormattableContentFormatter?
    private let formatter = FormattableContentFormatter()

    override func setUp() {
        super.setUp()
        subject = FormattableContentFormatter()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testCachedObjectsCanBeFetched() {
        let key = "key"
        let value = "value"

        subject?.setCacheValue(value as AnyObject, forKey: key)

        let fetchedObject = subject?.cacheValueForKey(key) as? String

        XCTAssertEqual(fetchedObject, value)
    }

    func testCachedObjectsCanBeOvewriten() {
        let key = "key"
        let value = "value"

        subject?.setCacheValue(value as AnyObject, forKey: key)
        subject?.setCacheValue(nil, forKey: key)

        let fetchedObject = subject?.cacheValueForKey(key)

        XCTAssertNil(fetchedObject)
    }

    func testCachedCanBeReset() {
        let key = "key"
        let value = "value"

        subject?.setCacheValue(value as AnyObject, forKey: key)
        subject?.resetCache()

        let fetchedObject = subject?.cacheValueForKey(key)

        XCTAssertNil(fetchedObject)
    }

    func testNoticonRangeIsFormattedCorrectly() {
        let content = contentWithNoticon()
        let formattedText = formatter.render(content: content, with: RichTextContentStyles())

        XCTAssertEqual(formattedText.string, Constants.textExpectation)
    }

    func testInvalidRange() {
        let postProperties = NotificationContentRange.Properties(range: NSRange(location: 0, length: 1))

        let content = FormattableTextContent(text: "", ranges: [
            NotificationContentRange(kind: .post, properties: postProperties)
        ])

        let formattedText = formatter.render(content: content, with: SubjectContentStyles())
        XCTAssert(formattedText.length == 0)
    }

    func testConsecutiveSpacesAreCollapsed() {
        let content = FormattableTextContent(text: "Hello    world", ranges: [])
        let formattedText = formatter.render(content: content, with: RichTextContentStyles())

        // Runs of spaces are collapsed into one regular space followed by hairline spaces,
        // keeping the string length intact so range-based formatting still applies.
        XCTAssertEqual(formattedText.string, "Hello \u{200A}\u{200A}\u{200A}world")
        XCTAssertEqual(formattedText.string.count, "Hello    world".count)
    }

    func testSingleSpaceIsPreserved() {
        let content = FormattableTextContent(text: "Hello world", ranges: [])
        let formattedText = formatter.render(content: content, with: RichTextContentStyles())

        XCTAssertEqual(formattedText.string, "Hello world")
    }

    private func contentWithNoticon() -> FormattableTextContent {
        let range = FormattableNoticonRange(value: Constants.noticon, range: Constants.range)
        return FormattableTextContent(text: Constants.text, ranges: [range])
    }
}

private enum Constants {
    static let noticon = "\u{f442}"
    static let text = "Hello world"
    static let textExpectation = noticon + " " + text
    static let range = NSRange(location: 0, length: 0)
}
