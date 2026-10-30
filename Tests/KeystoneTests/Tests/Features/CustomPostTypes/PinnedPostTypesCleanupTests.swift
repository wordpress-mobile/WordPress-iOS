import Foundation
import Testing

@testable import WordPress

@Suite("Pinned post types cleanup")
struct PinnedPostTypesCleanupTests {
    @Test("removes only the pinned post types keys")
    func removesPinnedPostTypesKeys() throws {
        let suiteName = "PinnedPostTypesCleanupTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let pinnedA = "site-storage|x-coredata://STORE/Blog/p1|pinned-post-types"
        let pinnedB = "site-storage|x-coredata://STORE/Blog/p2|pinned-post-types"
        let otherSiteStorage = "site-storage|x-coredata://STORE/Blog/p1|other-key"
        let unrelated = "unrelated-key"
        for key in [pinnedA, pinnedB, otherSiteStorage, unrelated] {
            defaults.set(Data([1]), forKey: key)
        }

        SiteStorageAccess.removePinnedPostTypes(from: defaults)

        #expect(defaults.object(forKey: pinnedA) == nil)
        #expect(defaults.object(forKey: pinnedB) == nil)
        #expect(defaults.object(forKey: otherSiteStorage) != nil)
        #expect(defaults.object(forKey: unrelated) != nil)
    }
}
