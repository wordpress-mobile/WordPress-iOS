import XCTest

@testable import WordPress

class PostSignUpInterstitialCoordinatorTests: XCTestCase {
    let testUserId = 12345 as NSNumber
    let userDefaultsKeyFormat = "PostSignUpInterstitial.hasSeenBefore.%@"

    func testShouldNotDisplay() {
        let database = EphemeralKeyValueDatabase()
        let coordinator = PostSignUpInterstitialCoordinator(database: database, userId: testUserId)

        XCTAssertFalse(coordinator.shouldDisplay(numberOfBlogs: 10))
    }

    func testShouldDisplay() {
        let database = EphemeralKeyValueDatabase()
        let coordinator = PostSignUpInterstitialCoordinator(database: database, userId: testUserId)

        XCTAssertTrue(coordinator.shouldDisplay(numberOfBlogs: 0))
    }

    func testHasSeenBeforeTrue() {
        let database = EphemeralKeyValueDatabase()
        let userId = testUserId
        let key = String(format: userDefaultsKeyFormat, userId)
        database.set(true, forKey: key)

        let coordinator = PostSignUpInterstitialCoordinator(database: database, userId: userId)

        XCTAssertTrue(coordinator.hasSeenBefore())
    }

    func testHasSeenBeforeFalse() {
        let database = EphemeralKeyValueDatabase()
        let userId = testUserId
        let coordinator = PostSignUpInterstitialCoordinator(database: database, userId: userId)

        XCTAssertFalse(coordinator.hasSeenBefore())
    }

    func testMarkAsSeen() {
        let database = EphemeralKeyValueDatabase()
        let userId = testUserId

        let coordinator = PostSignUpInterstitialCoordinator(database: database, userId: userId)
        coordinator.markAsSeen()

        let key = String(format: userDefaultsKeyFormat, userId)
        let value = database.bool(forKey: key)

        XCTAssertTrue(value)
    }
}
