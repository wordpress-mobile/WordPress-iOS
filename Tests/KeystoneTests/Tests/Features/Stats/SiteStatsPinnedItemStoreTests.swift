import XCTest
@testable import WordPress

final class SiteStatsPinnedItemStoreTests: XCTestCase {
    let featureFlags = FeatureFlagOverrideStore()
    var store: SiteStatsPinnedItemStore!
    var jetpackNotificationMigrationService: JetpackNotificationMigrationServiceMock!

    override func setUpWithError() throws {
        jetpackNotificationMigrationService = JetpackNotificationMigrationServiceMock()
        store = SiteStatsPinnedItemStore(siteId: 0, jetpackNotificationMigrationService: jetpackNotificationMigrationService)
    }

    func testPinnedItemsShouldContainBloggingRemindersWhenWPNotificationsEnabled() throws {
        jetpackNotificationMigrationService.shouldPresentNotificationsToReturn = true
        XCTAssertTrue(itemsContainsBloggingReminders())
    }

    func itemsContainsBloggingReminders() -> Bool {
        return store.items.contains(where: { item in
            if case is GrowAudienceCell.HintType = item {
                return item as! GrowAudienceCell.HintType == .bloggingReminders
            }
            return false
        })
    }
}

class JetpackNotificationMigrationServiceMock: JetpackNotificationMigrationServiceProtocol {
    var shouldPresentNotificationsToReturn = false

    func shouldPresentNotifications() -> Bool {
        return shouldPresentNotificationsToReturn
    }
}
