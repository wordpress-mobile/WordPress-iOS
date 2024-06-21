import XCTest
@testable import WordPressKit

final class StatsAnnualAndMostPopularTimeInsightDecodingTests: XCTestCase {

    func testDecodingWithAllRequiredParametersIsSuccessful() {
        // Given
        let json: [String: Any] = [
            "highest_hour": 1,
            "highest_hour_percent": 1,
            "highest_day_of_week": 1,
            "highest_day_percent": 1
        ]

        // When
        let insight = StatsAnnualAndMostPopularTimeInsight(jsonDictionary: json as [String: AnyObject])

        // Then
        XCTAssertNotNil(insight)
    }

    func testDecodingWithoutAllRequiredParametersIsUnsuccessful() {
        // Given
        let json: [String: Any] = [
            "highest_hour": 1,
            "highest_hour_percent": 1,
            "highest_day_of_week": 1
        ]

        // When
        let insight = StatsAnnualAndMostPopularTimeInsight(jsonDictionary: json as [String: AnyObject])

        // Then
        XCTAssertNil(insight)
    }

    func testDecodingDecimalPercentagesRoundsSuccessful() {
        // Given
        let json: [String: Any] = [
            "highest_hour": 1,
            "highest_hour_percent": 20.5,
            "highest_day_of_week": 1,
            "highest_day_percent": 5.4,
            "years": [["year": "2022"]]
        ]

        // When
        let insight = StatsAnnualAndMostPopularTimeInsight(jsonDictionary: json as [String: AnyObject])

        // Then
        XCTAssertEqual(insight?.mostPopularHourPercentage, 21)
        XCTAssertEqual(insight?.mostPopularDayOfWeekPercentage, 5)
    }
}
