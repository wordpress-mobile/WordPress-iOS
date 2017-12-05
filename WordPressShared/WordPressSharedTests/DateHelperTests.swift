import XCTest
@testable import WordPressShared

class DateHelperTests: XCTestCase {
    struct UnexpectedNilError: Error {}

    func testToStringForPortfolioSections() throws {
        let cal = Calendar.current
        let now = Date()
        // Test "recent" dates
        // => now (almost)
        XCTAssertEqual(now.toStringForPortfolioSections(), NSLocalizedString("recent", comment: ""))
        // => yesterday
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(yesterday.toStringForPortfolioSections(), NSLocalizedString("recent", comment: ""))
        // Test dates within "last 7 days" time frame
        // => 5 days ago
        guard let fiveDaysAgo = cal.date(byAdding: .day, value: -5, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(fiveDaysAgo.toStringForPortfolioSections(), NSLocalizedString("last 7 days", comment: ""))
        // Test dates within "last 30 days" time frame
        // => 8 days ago
        guard let eightDaysAgo = cal.date(byAdding: .day, value: -8, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(eightDaysAgo.toStringForPortfolioSections(), NSLocalizedString("last 30 days", comment: ""))
        // => 15 days ago
        guard let fifteenDaysAgo = cal.date(byAdding: .day, value: -15, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(fifteenDaysAgo.toStringForPortfolioSections(), NSLocalizedString("last 30 days", comment: ""))
        // Test an "earlier" dates
        guard let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(twoMonthsAgo.toStringForPortfolioSections(), NSLocalizedString("earlier", comment: ""))
        // Test a future date
        guard let inFourDays = cal.date(byAdding: .day, value: 4, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(inFourDays.toStringForPortfolioSections(), NSLocalizedString("later", comment: ""))
    }

}

