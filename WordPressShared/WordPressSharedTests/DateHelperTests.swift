import XCTest
@testable import WordPressShared

class DateHelperTests: XCTestCase {
    struct UnexpectedNilError: Error {}

    func testToStringForPortfolioSections() throws {
        // Test a recent date
        let cal = Calendar.current
        let now = Date()
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(yesterday.toStringForPortfolioSections(), NSLocalizedString("recent", comment: ""))
        // Test a date from last week
        guard let oneWeekAgo = cal.date(byAdding: .weekOfYear, value: -1, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(oneWeekAgo.toStringForPortfolioSections(), NSLocalizedString("last week", comment: ""))
        // Test a date from last month
        guard let threeWeeksAgo = cal.date(byAdding: .weekOfYear, value: -3, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(threeWeeksAgo.toStringForPortfolioSections(), NSLocalizedString("last month", comment: ""))
        // Test an older date
        guard let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(twoMonthsAgo.toStringForPortfolioSections(), NSLocalizedString("before", comment: ""))
        // Test a future date
        guard let inFourDays = cal.date(byAdding: .day, value: 4, to: now) else {
            throw UnexpectedNilError()
        }
        XCTAssertEqual(inFourDays.toStringForPortfolioSections(), NSLocalizedString("later", comment: ""))
    }

}

