import XCTest
import WordPressKit
import Combine
@testable import WordPress

final class StatsSubscribersViewModelTests: XCTestCase {
    private var sut: StatsSubscribersViewModel!
    private var store: StatsSubscribersStoreMock!
    private var cancellables: Set<AnyCancellable> = []

    override func setUpWithError() throws {
        store = StatsSubscribersStoreMock()
        sut = StatsSubscribersViewModel(store: store)
        sut.addObservers()
    }

    func testTableViewSnapshot_loading() throws {
        let expectation = expectation(description: "First section should be loading")
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let _ = snapshot.itemIdentifiers.first?.immuTableRow as? StatsGhostTopImmutableRow {
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        store.chartSummary.send(.loading)

        wait(for: [expectation], timeout: 1)
    }

    func testTableViewSnapshot_chartSummaryLoaded() throws {
        let expectation = expectation(description: "Chart section should be loading")
        var subscriberChartRow: SubscriberChartRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers.first?.immuTableRow as? SubscriberChartRow {
                    subscriberChartRow = row
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        let chartSummary = StatsSubscribersSummaryData(history: [
            .init(date: Date(), count: 1),
            .init(date: Date(), count: 2),
        ])
        store.chartSummary.send(.success(chartSummary))

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(subscriberChartRow?.chartData)
    }

    func testTableViewSnapshot_emailsSummaryLoaded() throws {
        let expectation = expectation(description: "Email section should be loading")
        var emailsSummaryRow: TopTotalsPeriodStatsRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers.last?.immuTableRow as? TopTotalsPeriodStatsRow {
                    emailsSummaryRow = row
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        let emailsSummary = StatsEmailsSummaryData(posts: [
            .init(id: 1, link: URL(string: "https://example.com")!, date: Date(), title: "Title", type: .post, opens: 1, clicks: 154),
            .init(id: 2, link: URL(string: "https://example.com")!, date: Date(), title: "Title 2", type: .post, opens: 10, clicks: 0)
        ])
        store.emailsSummary.send(.success(emailsSummary))

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(emailsSummaryRow?.dataRows.count, 2)
        XCTAssertEqual(emailsSummaryRow?.dataRows.first?.name, "Title")
        XCTAssertEqual(emailsSummaryRow?.dataRows.first?.data, "1")
        XCTAssertEqual(emailsSummaryRow?.dataRows.first?.secondData, "154")
    }
}

private class StatsSubscribersStoreMock: StatsSubscribersStoreProtocol {
    var chartSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersSummaryData>, Never> = .init(.idle)
    var emailsSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsEmailsSummaryData>, Never> = .init(.idle)
    var updateChartSummaryCalled = false
    var updateEmailsSummaryCalled = false

    func updateChartSummary() {
        updateChartSummaryCalled = false
    }

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField) {
        updateEmailsSummaryCalled = true
    }
}
