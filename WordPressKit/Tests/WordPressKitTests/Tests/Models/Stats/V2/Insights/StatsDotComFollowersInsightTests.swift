import XCTest
@testable import WordPressKit

class StatsDotComFollowersInsightTests: XCTestCase {

    func testInitializingWithNoData() {
        // Given
        let jsonDictionary = getFollowerDictionary()

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertNil(follower)
    }

    func testInitializingWithNoId() {
        // Given
        let date = Date(timeIntervalSince1970: 0)
        let name = "Test"
        let avatarUrl = "https://localhost/image"
        let expectedUrl = getUrl(from: avatarUrl)
        let jsonDictionary = getFollowerDictionary(name: name, subscribedDate: date, avatarUrl: avatarUrl)

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertNil(follower?.id)
        XCTAssertEqual(follower?.name, name)
        XCTAssertEqual(follower?.subscribedDate, date)
        XCTAssertEqual(follower?.avatarURL, expectedUrl)
    }

    func testInitializingWithId() {
        // Given
        let id = "1234567890"
        let date = Date(timeIntervalSince1970: 0)
        let name = "Test"
        let avatarUrl = "https://localhost/image"
        let jsonDictionary = getFollowerDictionary(id: id, name: name, subscribedDate: date, avatarUrl: avatarUrl)

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertEqual(follower?.id, id)
    }

    func testInitializingWithMissingName() {
        // Given
        let id = "1234567890"
        let date = Date(timeIntervalSince1970: 0)
        let avatarUrl = "https://localhost/image"
        let jsonDictionary = getFollowerDictionary(id: id, subscribedDate: date, avatarUrl: avatarUrl)

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertNil(follower)
    }

    func testInitializingWithMissingDate() {
        // Given
        let id = "1234567890"
        let name = "Test"
        let avatarUrl = "https://localhost/image"
        let jsonDictionary = getFollowerDictionary(id: id, name: name, avatarUrl: avatarUrl)

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertNil(follower)
    }

    func testInitializingWithMissingAvatar() {
        // Given
        let id = "1234567890"
        let name = "Test"
        let date = Date(timeIntervalSince1970: 0)
        let jsonDictionary = getFollowerDictionary(id: id, name: name, subscribedDate: date)

        // When
        let follower = StatsFollower(jsonDictionary: jsonDictionary)

        // Then
        XCTAssertNotNil(follower)
    }

}

// MARK: - Test functions

private extension StatsDotComFollowersInsightTests {

    func getFollowerDictionary(id: String? = nil, name: String? = nil, subscribedDate: Date? = nil, avatarUrl: String? = nil) -> [String: AnyObject] {
        var dateString: String?

        if let subscribedDate = subscribedDate {
            let dateFormatter = ISO8601DateFormatter()
            dateString = dateFormatter.string(from: subscribedDate)
        }

        return [
            "ID": id,
            "label": name,
            "date_subscribed": dateString,
            "avatar": avatarUrl
        ].compactMapValues { $0 as AnyObject }
    }

    func getUrl(from urlString: String) -> URL? {
        guard var components = URLComponents(string: urlString) else { return nil }
        components.query = "d=mm&s=60"

        return try? components.asURL()
    }

}
