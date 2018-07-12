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
    let themeText = "Spatial"
    let settingsText = "Default post category changed from \"subcategory\" to \"viajes\""

    let activityLogJSON = ActivityLogJSON()
    let parent = MockActivityParent()
    let actionsParser = ActivityActionsParser()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPingbackContentIsParsedCorrectly() {
        let dictionary = activityLogJSON.getPingbackDictionary()

        let pingbackContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(pingbackContent.count, 1)

        let pingback = pingbackContent[0]

        XCTAssertEqual(pingback.text, pingbackText)
        XCTAssertEqual(pingback.ranges.count, 2)
        XCTAssertEqual(pingback.ranges.first?.kind, .default)
        XCTAssertEqual(pingback.ranges.last?.kind, .post)
    }

    func testPostContentIsParsedCorrectly() {
        let dictionary = activityLogJSON.getPostContentDictionary()
        let postContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(postContent.count, 1)

        let post = postContent[0]

        XCTAssertEqual(post.text, postText)
        XCTAssertEqual(post.ranges.count, 1)
        XCTAssertEqual(post.ranges.first?.kind, .post)
    }

    func testCommentContentIsParsedCorrectly() {
        let dictionary = activityLogJSON.getCommentContentDictionary()
        let commentContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(commentContent.count, 1)

        let comment = commentContent[0]

        XCTAssertEqual(comment.text, commentText)
        XCTAssertEqual(comment.ranges.count, 2)
        XCTAssertEqual(comment.ranges.first?.kind, .comment)
        XCTAssertEqual(comment.ranges.last?.kind, .post)
    }

    func testThemeContentIsParsedCorrectly() {
        let dictionary = activityLogJSON.getThemeContentDictionary()
        let themeContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(themeContent.count, 1)

        let theme = themeContent[0]

        XCTAssertEqual(theme.text, themeText)
        XCTAssertEqual(theme.ranges.count, 1)
        XCTAssertEqual(theme.ranges.first?.kind, .theme)
    }

    func testSettingContentIsParsedCorrectly() {
        let dictionary = activityLogJSON.getSettingsContentDictionary()
        let settingsContent = ActivityFormattableContentFactory.content(from: [dictionary], actionsParser: actionsParser, parent: parent)

        XCTAssertEqual(settingsContent.count, 1)

        let settings = settingsContent[0]

        XCTAssertEqual(settings.text, settingsText)
        XCTAssertEqual(settings.ranges.count, 2)
        XCTAssertEqual(settings.ranges.first?.kind, .italic)
        XCTAssertEqual(settings.ranges.last?.kind, .italic)
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

    func getThemeContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-theme-content.json")
    }

    func getSettingsContentDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-settings-content.json")
    }

    func getCommentRangeDictionary() -> [String: AnyObject] {
        let dictionary = getCommentContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getPostRangeDictionary() -> [String: AnyObject] {
        let dictionary = getPostContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getThemeRangeDictionary() -> [String: AnyObject] {
        let dictionary = getThemeContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    func getItalicRangeDictionary() -> [String: AnyObject] {
        let dictionary = getSettingsContentDictionary()
        return getRange(at: 0, from: dictionary)
    }

    private func getRange(at index: Int, from dictionary: [String: AnyObject]) -> [String: AnyObject] {
        let ranges = getRanges(from: dictionary)
        return ranges[index]
    }

    private func getRanges(from dictionary: [String: AnyObject]) -> [[String: AnyObject]] {
        return dictionary["ranges"] as! [[String: AnyObject]]
    }
}
