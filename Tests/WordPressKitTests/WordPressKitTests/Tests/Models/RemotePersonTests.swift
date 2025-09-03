import XCTest
@testable import WordPressKit

class RemotePersonTests: XCTestCase {

    // MARK: - EmailFollower tests

    func testEmailFollowerKind() {
        XCTAssertEqual(EmailFollower.kind, .emailFollower)
    }

    func testConvertingFromStatsFollower() {
        // Given
        let date = Date(timeIntervalSince1970: 0)
        let url = URL(string: "https://localhost/image")
        let id = "1234567890"
        let name = "test@test.com"
        let statsFollower = StatsFollower(name: name, subscribedDate: date, avatarURL: url, id: id)
        let siteId = 5

        // When
        let follower = EmailFollower(siteID: siteId, statsFollower: statsFollower)

        // Then
        let expectedId = Int(id)
        XCTAssertEqual(follower?.ID, expectedId)
        XCTAssertEqual(follower?.username, "")
        XCTAssertNil(follower?.firstName)
        XCTAssertNil(follower?.lastName)
        XCTAssertEqual(follower?.displayName, name)
        XCTAssertEqual(follower?.role, "")
        XCTAssertEqual(follower?.siteID, siteId)
        XCTAssertEqual(follower?.linkedUserID, expectedId)
        XCTAssertEqual(follower?.avatarURL, url)
        XCTAssertFalse(follower?.isSuperAdmin ?? true)
    }

    func testConvertingWithNilStatsFollower() {
        // Given
        let siteId = 5

        // When
        let follower = EmailFollower(siteID: siteId, statsFollower: nil)

        // Then
        XCTAssertNil(follower)
    }

    func testConvertingWithInvalidId() {
        // Given
        let date = Date(timeIntervalSince1970: 0)
        let url = URL(string: "https://localhost/image")
        let id = "Not an int"
        let name = "test@test.com"
        let statsFollower = StatsFollower(name: name, subscribedDate: date, avatarURL: url, id: id)
        let siteId = 5

        // When
        let follower = EmailFollower(siteID: siteId, statsFollower: statsFollower)

        // Then
        XCTAssertNil(follower)
    }

}
