@testable import WordPress
@testable import WordPressKit
import XCTest
import WordPressFlux


struct MockAnnouncementsCache: AnnouncementsCache {

    var announcements: [Announcement]?

    var date: Date?

    private let localAnnouncements = [Announcement(appVersionName: "0.0",
                                           minimumAppVersion: "1.0",
                                           maximumAppVersion: "3.0",
                                           appVersionTargets: [],
                                           detailsUrl: "http://wordpress.org",
                                           announcementVersion: "1.0",
                                           isLocalized: false,
                                           responseLocale: "",
                                           features: [WordPressKit.Feature(title: "first cached feature",
                                                                           subtitle: "this is a mock cached feature",
                                                                           iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-personal.png",
                                                                           iconBase64: nil),
                                                      WordPressKit.Feature(title: "second cached feature",
                                                                           subtitle: "this is a mock cached feature",
                                                                           iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-personal.png",
                                                                           iconBase64: nil)])]

    init(localCacheIsValid: Bool = true) {
        self.announcements = localCacheIsValid ? localAnnouncements : nil
    }
}

class MockAnnouncementsService: AnnouncementServiceRemote {

    var getAnnouncementsExpectation: XCTestExpectation?
    var getAnnouncementsSucceeds = true

    private let successResult: Result<[Announcement], Error> = .success([Announcement(appVersionName: "0.0",
                                                                                      minimumAppVersion: "0.0",
                                                                                      maximumAppVersion: "infinity",
                                                                                      appVersionTargets: [],
                                                                                      detailsUrl: "http://wordpress.org",
                                                                                      announcementVersion: "1.0",
                                                                                      isLocalized: false,
                                                                                      responseLocale: "",
                                                                                      features: [WordPressKit.Feature(title: "mock feature",
                                                                                                                      subtitle: "this is a mock feature",
                                                                                                                      iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-personal.png",
                                                                                                                      iconBase64: nil)])])

    private let failureResult: Result<[Announcement], Error> = .failure(NSError(domain: "mock error", code: 0, userInfo: nil))

    override func getAnnouncements(appId: String,
                                   appVersion: String,
                                   locale: String,
                                   completion: @escaping (Result<[Announcement], Error>) -> Void) {

        getAnnouncementsExpectation?.fulfill()
        let result = getAnnouncementsSucceeds ? successResult : failureResult
        completion(result)

    }
}

struct MockVersionProvider: AnnouncementsVersionProvider {

    var version: String? = "2.0"
}


class AnnouncementsDataStoreTests: XCTestCase {

    private var subscription: Receipt?

    /// local cache contains valid announcements
    func testLocalAnnouncementsRetrieved() {
        // Given
        let cache = MockAnnouncementsCache()
        let service = MockAnnouncementsService()
        let versionProvider = MockVersionProvider()
        let store = CachedAnnouncementsStore(cache: cache, service: service, versionProvider: versionProvider)
        let stateChangeExpectation = expectation(description: "state change emitted")

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            XCTAssertNotNil(store.announcements.first)
            XCTAssertEqual(["first cached feature", "second cached feature"], store.announcements.first?.features.map { $0.title })
        }
        // When
        store.getAnnouncements()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    /// local cache not found and remote announcements retrieved correctly
    func testRemoteAnnouncementsSuccess() {
        // Given
        let cache = MockAnnouncementsCache()
        let service = MockAnnouncementsService()
        var versionProvider = MockVersionProvider()
        versionProvider.version = "4.0" // out of version range -> invalid
        let store = CachedAnnouncementsStore(cache: cache, service: service, versionProvider: versionProvider)
        let stateChangeExpectation = expectation(description: "state change emitted")

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            XCTAssertNotNil(store.announcements.first)
            XCTAssertEqual(["mock feature"], store.announcements.first?.features.map { $0.title })
        }
        // When
        store.getAnnouncements()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    /// local cache not found and remote announcements fail
    func testRemoteAnnouncementsFailure() {
        // Given
        let cache = MockAnnouncementsCache(localCacheIsValid: false)
        let service = MockAnnouncementsService()
        service.getAnnouncementsSucceeds = false
        let versionProvider = MockVersionProvider()
        let store = CachedAnnouncementsStore(cache: cache, service: service, versionProvider: versionProvider)
        let stateChangeExpectation = expectation(description: "state change emitted")

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            XCTAssertNil(store.announcements.first)
            switch store.state {
            case .error(let error as NSError):
                XCTAssertEqual(error.domain, "mock error")
            default:
                XCTFail("Error did not propagate successfully")
            }
        }

        // When
        store.getAnnouncements()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testCacheWasUpdated() {
        // Given
        let cache = MockAnnouncementsCache()
        let service = MockAnnouncementsService()
        let getAnnouncementsExpectation = expectation(description: "Get announcements called")
        service.getAnnouncementsExpectation = getAnnouncementsExpectation
        let versionProvider = MockVersionProvider()
        let store = CachedAnnouncementsStore(cache: cache, service: service, versionProvider: versionProvider)
        let stateChangeExpectation = expectation(description: "state change emitted")

        subscription = store.onChange {
            stateChangeExpectation.fulfill()
            XCTAssertNotNil(store.announcements.first)
            XCTAssertEqual(["first cached feature", "second cached feature"], store.announcements.first?.features.map { $0.title })
        }
        // When
        store.getAnnouncements()
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}
