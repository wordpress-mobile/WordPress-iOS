import XCTest
@testable import WordPress

final class FormattableContentFormatterTests: XCTestCase {
    private var subject: FormattableContentFormatter?

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
}
