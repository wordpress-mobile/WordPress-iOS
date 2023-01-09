import Foundation
import XCTest
@testable import WordPress

class SiteStatsInsightsDetailsViewModelTests: XCTestCase {

    var viewModel: SiteStatsInsightsDetailsViewModel!

    override func setUpWithError() throws {
        viewModel = SiteStatsInsightsDetailsViewModel(insightsDetailsDelegate: MockInsightsDelegate(),
                                                      detailsDelegate: MockDetailsDelegate(),
                                                      referrerDelegate: MockReferrerDeletage(),
                                                      viewsAndVisitorsDelegate: MockViewsAndVisitorsDelegate())

        viewModel.fetchDataFor(statSection: StatSection.insightsAddInsight)
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

private extension SiteStatsInsightsDetailsViewModelTests {
    class MockInsightsDelegate: SiteStatsInsightsDelegate { }

    class MockDetailsDelegate: SiteStatsDetailsDelegate { }

    class MockViewsAndVisitorsDelegate: StatsInsightsViewsAndVisitorsDelegate {
        func viewsAndVisitorsSegmendChanged(to selectedSegmentIndex: Int) {}
    }

    class MockReferrerDeletage: SiteStatsReferrerDelegate {
        func showReferrerDetails(_ data: StatsTotalRowData) { }
    }

    struct Constants {
        static let failCreateStatsSummaryTimeIntervalData = "Failed to create statsSummaryTimeIntervalData"
    }
}
