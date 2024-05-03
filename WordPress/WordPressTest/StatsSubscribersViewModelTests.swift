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

    func testTableViewSnapshot_subscribersTotalLoaded() throws {
        let expectation = expectation(description: "First section should be TotalInsightStatsRow")
        var subscribersTotalRow: TotalInsightStatsRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers[0].immuTableRow as? TotalInsightStatsRow {
                    subscribersTotalRow = row
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        store.subscribersList.send(.success(.init(subscribers: [], totalCount: 54)))

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(subscribersTotalRow?.dataRow.count, 54)
    }

    func testTableViewSnapshot_chartSummaryLoaded() throws {
        let expectation = expectation(description: "Second section should be SubscriberChartRow")
        var subscriberChartRow: SubscriberChartRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers[1].immuTableRow as? SubscriberChartRow {
                    subscriberChartRow = row
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        let chartSummary = StatsSubscribersSummaryData(history: [
            .init(date: Date(), count: 1),
            .init(date: Date(), count: 2),
        ], period: .day, periodEndDate: Date())
        store.chartSummary.send(.success(chartSummary))

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(subscriberChartRow?.chartData)
    }

    func testTableViewSnapshot_subscribersListLoaded() throws {
        let expectation = expectation(description: "Third section should be TopTotalsPeriodStatsRow")
        var subscribersListRow: TopTotalsPeriodStatsRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers[2].immuTableRow as? TopTotalsPeriodStatsRow {
                    subscribersListRow = row
                    expectation.fulfill()
                }
            })
            .store(in: &cancellables)

        let subscribers: [StatsFollower] = [
            .init(name: "First Subscriber", subscribedDate: Date(), avatarURL: nil),
            .init(name: "Second Subscriber", subscribedDate: Date(), avatarURL: nil),
            .init(name: "Third Subscriber", subscribedDate: Date(), avatarURL: nil)
        ]
        store.subscribersList.send(.success(.init(subscribers: subscribers, totalCount: 0)))

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(subscribersListRow?.dataRows.count, 3)
        XCTAssertEqual(subscribersListRow?.dataRows[0].name, "First Subscriber")
        XCTAssertEqual(subscribersListRow?.dataRows[2].name, "Third Subscriber")
    }

    func testTableViewSnapshot_emailsSummaryLoaded() throws {
        let expectation = expectation(description: "Fourth section should be TopTotalsPeriodStatsRow")
        var emailsSummaryRow: TopTotalsPeriodStatsRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers[3].immuTableRow as? TopTotalsPeriodStatsRow {
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
    var emailsSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsEmailsSummaryData>, Never> = .init(.idle)
    var subscribersList: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersData>, Never> = .init(.idle)
    var chartSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersSummaryData>, Never> = .init(.idle)

    var updateEmailsSummaryCalled = false
    var updateChartSummaryCalled = false
    var updateSubscribersListCalled = false

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField) {
        updateEmailsSummaryCalled = true
    }

    func updateChartSummary() {
        updateChartSummaryCalled = false
    }

    func updateSubscribersList(quantity: Int) {
        updateSubscribersListCalled = true
    }
}
