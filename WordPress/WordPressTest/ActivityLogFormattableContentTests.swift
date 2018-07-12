import XCTest
@testable import WordPress

class MockActivityParent: FormattableContentParent {
    var metaCommentID: NSNumber? = nil
    var uniqueID: String? = nil
    var kind: ParentKind = .Unknown
    var metaReplyID: NSNumber? = nil
    var isPingback: Bool = false

    func didChangeOverrides() {
    }

    func isEqual(to other: FormattableContentParent) -> Bool {
        return false
    }
}

final class ActivityLogFormattableContentTests: XCTestCase {

    let testPostID = 347
    let testSiteID = 137726971
    var testPostURL: String {
        return "https://wordpress.com/read/blogs/\(testSiteID)/posts/\(testPostID)"
    }
    let testText = "Pingback to Camino a Machu Picchu from Tren de Machu Picchu a Cusco – eToledo"

    let activityLogJSON = ActivityLogJSON()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPingbackContent() {
        let dictionary = activityLogJSON.getPingbackDictionary()
        let array = [dictionary]
        let parent = MockActivityParent()

        let pingbackContent = ActivityFormattableContentFactory.content(from: array, actionsParser: ActivityActionsParser(), parent: parent)

        XCTAssertEqual(pingbackContent.count, 1)

        let pingback = pingbackContent[0]

        XCTAssertEqual(pingback.text, testText)
        XCTAssertEqual(pingback.ranges.count, 2)
        XCTAssertEqual(pingback.ranges.first?.kind, .default)
        XCTAssertEqual(pingback.ranges.last?.kind, .post)
    }
}

class ActivityLogJSON {

    let contextManager = TestContextManager()

    func getPingbackDictionary() -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: "activity-log-pingback-content.json") as! [String : AnyObject]
    }

    func getPostRangeDictionary() -> [String: AnyObject] {
        let dictionary = getPingbackDictionary()
        let ranges = dictionary["ranges"] as! [[String: AnyObject]]
        return ranges[1]
    }
}
