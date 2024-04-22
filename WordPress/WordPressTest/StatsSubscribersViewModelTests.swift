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

        store.emailsSummary.send(.loading)

        wait(for: [expectation], timeout: 1)
    }

    func testTableViewSnapshot_emailsSummaryLoaded() throws {
        let expectation = expectation(description: "First section should be loading")
        var emailsSummaryRow: TopTotalsPeriodStatsRow?
        sut.tableViewSnapshot
            .sink(receiveValue: { snapshot in
                if let row = snapshot.itemIdentifiers.first?.immuTableRow as? TopTotalsPeriodStatsRow {
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
    var updateEmailsSummaryCalled = false

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField) {
        updateEmailsSummaryCalled = true
    }
}
