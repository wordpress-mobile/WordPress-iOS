import Nimble
@testable import WordPress
import XCTest

class CachedAnnouncementsStoreTests: XCTestCase {

    /// When the version is nil, the cache is never valid
    func testCacheIsValid_noVersion() {
        expect(makeStore(withVersion: .none).cacheIsValid(for: [])) == false
        expect(makeStore(withVersion: .none).cacheIsValid(for: [.fixture(minimumAppVersion: "1.0", maximumAppVersion: "2.0")])) == false
        expect(makeStore(withVersion: .none).cacheIsValid(for: [.fixture(appVersionTargets: ["1.1", "1.2"])])) == false
    }

    /// When the announcements list is empty, the cache is never valid
    func testCacheIsValid_noAnnouncements() {
        expect(makeStore(withVersion: .none).cacheIsValid(for: [])) == false
        expect(makeStore(withVersion: "1.0").cacheIsValid(for: [])) == false
    }

    /// When the first announcement version bounds include the given version, the cache is valid
    func testCacheIsValid_versionBounds() {
        let announcemens = [
            Announcement.fixture(minimumAppVersion: "1.0", maximumAppVersion: "2.0"),
            Announcement.fixture(minimumAppVersion: "2.1", maximumAppVersion: "3.0")
        ]

        expect(makeStore(withVersion: "1.0").cacheIsValid(for: announcemens)) == true
        expect(makeStore(withVersion: "1.1").cacheIsValid(for: announcemens)) == true
        expect(makeStore(withVersion: "1.0.1").cacheIsValid(for: announcemens)) == true
        expect(makeStore(withVersion: "2.0").cacheIsValid(for: announcemens)) == true

        expect(makeStore(withVersion: "0.9").cacheIsValid(for: announcemens)) == false
        expect(makeStore(withVersion: "2.1").cacheIsValid(for: announcemens)) == false
    }

    /// When the first announcement version targets includes the given version, the cache is valid
    func testCacheIsValid_versionTargets() {
        let announcements = [
            Announcement.fixture(
                minimumAppVersion: "3.0",
                maximumAppVersion: "3.1",
                appVersionTargets: ["0.9", "1.0", "2.1"]
            ),
            Announcement.fixture(
                minimumAppVersion: "4.0",
                maximumAppVersion: "4.1",
                appVersionTargets: ["4.9", "5.0", "5.1"]
            )
        ]

        expect(makeStore(withVersion: "0.9").cacheIsValid(for: announcements)) == true
        expect(makeStore(withVersion: "1.0").cacheIsValid(for: announcements)) == true
        expect(makeStore(withVersion: "2.1").cacheIsValid(for: announcements)) == true

        expect(makeStore(withVersion: "0.8").cacheIsValid(for: announcements)) == false
        expect(makeStore(withVersion: "1.1").cacheIsValid(for: announcements)) == false
        expect(makeStore(withVersion: "2.2").cacheIsValid(for: announcements)) == false
    }

    /// When the first announcement version bounds does not include the given version,
    /// the cache is never valid, regardless of the other announcements
    func testCacheIsValid_otherAnnouncementBounds() {
        let announcements = [
            Announcement.fixture(minimumAppVersion: "2.0", maximumAppVersion: "3.0"),
            Announcement.fixture(minimumAppVersion: "1.0", maximumAppVersion: "2.0")
        ]
        // These versions are valid for the second announcement, but the SUT only looks at the first.
        expect(makeStore(withVersion: "1.0").cacheIsValid(for: announcements)) == false
        expect(makeStore(withVersion: "1.1").cacheIsValid(for: announcements)) == false
        expect(makeStore(withVersion: "1.0.1").cacheIsValid(for: announcements)) == false
    }

    /// When the first announcement version bounds and app version targets do not include the given version,
    /// the cache is never valid, regardless of the other announcements
    func testCacheIsValid_otherAnnouncementVersionTargets() {
        let announcements = [
            Announcement.fixture(
                minimumAppVersion: "2.0",
                maximumAppVersion: "3.0",
                appVersionTargets: ["3.1", "3.2"]
            ),
            Announcement.fixture(
                minimumAppVersion: "1.0",
                maximumAppVersion: "1.5",
                appVersionTargets: ["1.6", "1.7"]
            )
        ]
        // These versions are valid for the second announcement, but the SUT only looks at the first.
        expect(makeStore(withVersion: "1.6").cacheIsValid(for: announcements)) == false
        expect(makeStore(withVersion: "1.7").cacheIsValid(for: announcements)) == false
    }
}

func makeStore(withVersion version: String?) -> CachedAnnouncementsStore {
    CachedAnnouncementsStore(
        cache: MockAnnouncementsCache(),
        service: MockAnnouncementsService(),
        versionProvider: MockVersionProvider(version: version)
    )
}
