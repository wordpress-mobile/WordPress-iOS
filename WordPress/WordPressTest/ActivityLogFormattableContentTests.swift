import XCTest
@testable import WordPress

final class ActivityLogFormattableContentTests: XCTestCase {

    let testData = ActivityLogTestData()
    let actionsParser = ActivityActionsParser()

    func testPingbackContentIsParsedCorrectly() {
        let dictionary = testData.getPingbackDictionary()

        let pingbackContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(pingbackContent.count, 1)

        let pingback = pingbackContent[0]

        XCTAssertEqual(pingback.text, testData.pingbackText)
        XCTAssertEqual(pingback.ranges.count, 2)
        XCTAssertEqual(pingback.ranges.first?.kind, .default)
        XCTAssertEqual(pingback.ranges.last?.kind, .post)
    }

    func testPostContentIsParsedCorrectly() {
        let dictionary = testData.getPostContentDictionary()
        let postContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(postContent.count, 1)

        let post = postContent[0]

        XCTAssertEqual(post.text, testData.postText)
        XCTAssertEqual(post.ranges.count, 1)
        XCTAssertEqual(post.ranges.first?.kind, .post)
    }

    func testCommentContentIsParsedCorrectly() {
        let dictionary = testData.getCommentContentDictionary()
        let commentContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(commentContent.count, 1)

        let comment = commentContent[0]

        XCTAssertEqual(comment.text, testData.commentText)
        XCTAssertEqual(comment.ranges.count, 2)
        XCTAssertEqual(comment.ranges.first?.kind, .comment)
        XCTAssertEqual(comment.ranges.last?.kind, .post)
    }

    func testThemeContentIsParsedCorrectly() {
        let dictionary = testData.getThemeContentDictionary()
        let themeContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(themeContent.count, 1)

        let theme = themeContent[0]

        XCTAssertEqual(theme.text, testData.themeText)
        XCTAssertEqual(theme.ranges.count, 1)
        XCTAssertEqual(theme.ranges.first?.kind, .theme)
    }

    func testSettingContentIsParsedCorrectly() {
        let dictionary = testData.getSettingsContentDictionary()
        let settingsContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(settingsContent.count, 1)

        let settings = settingsContent[0]

        XCTAssertEqual(settings.text, testData.settingsText)
        XCTAssertEqual(settings.ranges.count, 2)
        XCTAssertEqual(settings.ranges.first?.kind, .italic)
        XCTAssertEqual(settings.ranges.last?.kind, .italic)
    }

    func testSiteContentIsParsedCorreclty() {
        let dictionary = testData.getSiteContentDictionary()
        let siteContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(siteContent.count, 1)

        let site = siteContent[0]

        XCTAssertEqual(site.text, testData.siteText)
        XCTAssertEqual(site.ranges.count, 1)
        XCTAssertEqual(site.ranges.first?.kind, .site)
    }

    func testPluginContentIsParsedCorreclty() {
        let dictionary = testData.getPluginContentDictionary()
        let pluginContent = ActivityContentFactory.content(from: [dictionary], actionsParser: actionsParser)

        XCTAssertEqual(pluginContent.count, 1)

        let plugin = pluginContent[0]

        XCTAssertEqual(plugin.text, testData.pluginText)
        XCTAssertEqual(plugin.ranges.count, 1)
        XCTAssertEqual(plugin.ranges.first?.kind, .plugin)
    }
}
