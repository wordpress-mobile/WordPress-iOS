import Foundation
import XCTest
@testable import WordPress

class SiteStatsDetailsViewModelTests: XCTestCase {

    var viewModel: SiteStatsDetailsViewModel!

    override func setUpWithError() throws {
        viewModel = SiteStatsDetailsViewModel(detailsDelegate: MockDetailsDelegate(),
                                              referrerDelegate: MockReferrerDeletage())
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewModel = nil
    }

    func testUpdateSelectedDateBasecase() throws {
        // Given Date()
        let date = Date()

        // When updateSelectedDate with Date()
        viewModel.updateSelectedDate(date)

        // Then selectedDate should be Date()
        XCTAssertEqual(viewModel.selectedDate, date)
    }

    func testUpdateSelectedDateHistoricalDate() throws {
        // Given historical date
        let date = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 2, day: 21))!

        // When updateSelectedDate with historical date
        viewModel.updateSelectedDate(date)

        // Then selectedDate should be historical date
        XCTAssertEqual(viewModel.selectedDate, date)
    }

    func testUpdateSelectedDateFutureDate() throws {
        // Given future date
        let date = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 44, to: Date())!

        // When updateSelectedDate with future date
        viewModel.updateSelectedDate(date)

        guard let selectedDate = viewModel.selectedDate else {
            XCTFail("Failed to get set selectedDate")
            return
        }

        // Then selectedDate should be < future date
        XCTAssertTrue(selectedDate < date)

        // Then selectedDate should be same as currentDateForSite.
        // Using MediumString so that seconds / millis can be ignored in test
        XCTAssertEqual(selectedDate.toMediumString(), StatsDataHelper.currentDateForSite().toMediumString())
    }

}

private extension SiteStatsDetailsViewModelTests {
    class MockDetailsDelegate: SiteStatsDetailsDelegate {
        func tabbedTotalsCellUpdated() { }

        func displayWebViewWithURL(_ url: URL) { }

        func toggleChildRowsForRow(_ row: StatsTotalRow) { }

        func showPostStats(postID: Int, postTitle: String?, postURL: URL?) { }

        func displayMediaWithID(_ mediaID: NSNumber) { }
    }

    class MockReferrerDeletage: SiteStatsReferrerDelegate {
        func showReferrerDetails(_ data: StatsTotalRowData) { }
    }

    struct Constants {
        static let failCreateStatsSummaryTimeIntervalData = "Failed to create statsSummaryTimeIntervalData"
    }
}
