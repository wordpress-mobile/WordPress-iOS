import XCTest
import JetpackStatsWidgetsCore

@testable import WordPress

class StatsWidgetsStoreTests: CoreDataTestCase {
    private var sut: StatsWidgetsStore!
    private var appGroupName: String!
    private let appKeychainAccessGroup = "xctest_appKeychainAccessGroup"

    override func setUp() {
        super.setUp()

        let prefix = HomeWidgetCache<HomeWidgetTodayData>.testAppGroupNamePrefix
        appGroupName = "\(prefix)_\(UUID().uuidString)"
        deleteHomeWidgetData()
        sut = StatsWidgetsStore(
            coreDataStack: contextManager,
            appGroupName: appGroupName,
            appKeychainAccessGroup: appKeychainAccessGroup
        )
    }

    override func tearDown() {
        super.tearDown()

        deleteHomeWidgetData()
        sut = nil
    }

    func testStatsWidgetsDataInitializedAfterSignDidFinish() {
        BlogBuilder(contextManager.mainContext)
            .withAnAccount()
            .isHostedAtWPcom()
            .build()
        XCTAssertFalse(statsWidgetsHaveData())

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification), object: nil)

        XCTAssertTrue(statsWidgetsHaveData())
    }

    func testStatsWidgetsDeletedAfterDefaultWPAccountRemoved() {
        BlogBuilder(contextManager.mainContext)
            .withAnAccount()
            .isHostedAtWPcom()
            .build()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification), object: nil)

        NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            XCTAssertFalse(self.statsWidgetsHaveData())
        }
    }
}

private extension StatsWidgetsStoreTests {
    private func statsWidgetsHaveData() -> Bool {
        hasData(for: HomeWidgetTodayData.self) &&
        hasData(for: HomeWidgetThisWeekData.self) &&
        hasData(for: HomeWidgetAllTimeData.self)
    }

    private func deleteHomeWidgetData() {
        do {
            try makeCache(for: HomeWidgetTodayData.self).delete()
            try makeCache(for: HomeWidgetThisWeekData.self).delete()
            try makeCache(for: HomeWidgetAllTimeData.self).delete()
        } catch {
            // OK if it doesn't exist
        }
    }

    private func hasData<T: HomeWidgetData>(for type: T.Type) -> Bool {
        do {
            return try makeCache(for: type).read() != nil
        } catch {
            XCTFail("failed to read cache: \(error)")
            return false
        }
    }

    private func makeCache<T: HomeWidgetData>(for type: T.Type) -> HomeWidgetCache<T> {
        HomeWidgetCache<T>(appGroup: appGroupName)
    }
}
