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
    let pingbackText = "Pingback to Camino a Machu Picchu from Tren de Machu Picchu a Cusco – eToledo"
    let postText = "Tren de Machu Picchu a Cusco"
    let commentText = "Comment by levitoledo on Hola Lima! 🇵🇪: Great post! True talent!"

    let activityLogJSON = ActivityLogJSON()
    let parent = MockActivityParent()
    let actionsParser = ActivityActionsParser()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPingbackContent() {
        let dictionary = activityLogJSON.getPingbackDictionary()

        let pingbackContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(pingbackContent.count, 1)

        let pingback = pingbackContent[0]

        XCTAssertEqual(pingback.text, pingbackText)
        XCTAssertEqual(pingback.ranges.count, 2)
        XCTAssertEqual(pingback.ranges.first?.kind, .default)
        XCTAssertEqual(pingback.ranges.last?.kind, .post)
    }

    func testPostContent() {
        let dictionary = activityLogJSON.getPostContentDictionary()
        let postContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(postContent.count, 1)

        let post = postContent[0]

        XCTAssertEqual(post.text, postText)
        XCTAssertEqual(post.ranges.count, 1)
        XCTAssertEqual(post.ranges.first?.kind, .post)
    }

    func testCommentContent() {
        let dictionary = activityLogJSON.getCommentContentDictionary()
        let commentContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(commentContent.count, 1)

        let comment = commentContent[0]

        XCTAssertEqual(comment.text, commentText)
        XCTAssertEqual(comment.ranges.count, 2)
        XCTAssertEqual(comment.ranges.first?.kind, .comment)
        XCTAssertEqual(comment.ranges.last?.kind, .post)
    }
}

class ActivityLogJSON {

    let contextManager = TestContextManager()

    private func getDictionaryFromFile(named fileName: String) -> [String : AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String : AnyObject]
    }

    func getPingbackDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-pingback-content.json")
    }

    func getPostContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-post-content.json")
    }

    func getCommentContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-comment-content.json")
    }

    func getCommentRangeDictionary() -> [String: AnyObject] {
        let dictionary = getCommentContentDictionary()
        let ranges = getRanges(from: dictionary)
        return ranges[0]
    }

    func getPostRangeDictionary() -> [String: AnyObject] {
        let dictionary = getPostContentDictionary()
        let ranges = getRanges(from: dictionary)
        return ranges[0]
    }

    private func getRanges(from dictionary: [String: AnyObject]) -> [[String: AnyObject]] {
        return dictionary["ranges"] as! [[String: AnyObject]]
    }
}
