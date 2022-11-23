import XCTest
@testable import WordPress

final class SiteStatsPinnedItemStoreTests: XCTestCase {

    let store = SiteStatsPinnedItemStore(siteId: 1)
    let featureFlags = FeatureFlagOverrideStore()

    func testPinnedItemsShouldContainBloggingRemindersWhenFeatureFlagEnabled() throws {
        try featureFlags.override(FeatureFlag.bloggingReminders, withValue: true)
        XCTAssertTrue(itemsContainsBloggingReminders())
    }

    func testPinnedItemsShouldNotContainBloggingRemindersWhenFeatureFlagDisabled() throws {
        try featureFlags.override(FeatureFlag.bloggingReminders, withValue: false)
        XCTAssertFalse(itemsContainsBloggingReminders())
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
