import WordPressAuthenticator
import XCTest

@testable import WordPress

class StatsWidgetsStoreTests: CoreDataTestCase {
    private var sut: StatsWidgetsStore!
    private var blogService: BlogServiceMock!

    override func setUpWithError() throws {
        deleteHomeWidgetData()
        blogService = BlogServiceMock(managedObjectContext: mainContext)
        sut = StatsWidgetsStore(blogService: blogService)
    }

    override func tearDownWithError() throws {
        deleteHomeWidgetData()
        blogService = nil
        sut = nil
    }

    func testStatsWidgetsDataInitializedAfterSignDidFinish() {
        let blog = blogService.createBlog()
        blogService.visibleBlogsForWPComAccountsValue = [blog]
        XCTAssertFalse(statsWidgetsHaveData())

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

        XCTAssertTrue(statsWidgetsHaveData())
    }

    func testStatsWidgetsDeletedAfterDefaultWPAccountRemoved() {
        let blog = blogService.createBlog()
        blogService.visibleBlogsForWPComAccountsValue = [blog]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        XCTAssertFalse(statsWidgetsHaveData())
    }
}

private extension StatsWidgetsStoreTests {
    private func statsWidgetsHaveData() -> Bool {
        return HomeWidgetTodayData.read() != nil
        || HomeWidgetThisWeekData.read() != nil
        || HomeWidgetAllTimeData.read() != nil
    }

    private func deleteHomeWidgetData() {
        HomeWidgetTodayData.delete()
        HomeWidgetThisWeekData.delete()
        HomeWidgetAllTimeData.delete()
    }
}
