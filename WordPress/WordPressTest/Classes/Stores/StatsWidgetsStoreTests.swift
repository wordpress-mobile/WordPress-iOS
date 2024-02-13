import WordPressAuthenticator
import XCTest

@testable import WordPress

class StatsWidgetsStoreTests: CoreDataTestCase {
    private var sut: StatsWidgetsStore!

    override func setUp() {
        deleteHomeWidgetData()
        sut = StatsWidgetsStore(coreDataStack: contextManager)
    }

    override func tearDown() {
        deleteHomeWidgetData()
        sut = nil
    }

    func testStatsWidgetsDataInitializedAfterSignDidFinish() {
        BlogBuilder(contextManager.mainContext)
            .with(visible: true)
            .withAnAccount()
            .isHostedAtWPcom()
            .build()
        XCTAssertFalse(statsWidgetsHaveData())

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

        XCTAssertTrue(statsWidgetsHaveData())
    }

    func testStatsWidgetsDeletedAfterDefaultWPAccountRemoved() {
        BlogBuilder(contextManager.mainContext)
            .with(visible: true)
            .withAnAccount()
            .isHostedAtWPcom()
            .build()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            XCTAssertFalse(self.statsWidgetsHaveData())
        }

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
