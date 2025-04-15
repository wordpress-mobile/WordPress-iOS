import WordPressKit
import WordPressFlux
import XCTest

@testable import WordPress

class StatsRevampStoreTests: XCTestCase {
    private var dispatcher: ActionDispatcher!
    private var sut: StatsRevampStore!

    override func setUp() {
        super.setUp()
        dispatcher = ActionDispatcher()
        sut = StatsRevampStore(dispatcher: dispatcher)
    }

    override func tearDown() {
        dispatcher = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Statuses

    func testViewsAndVisitorsStatusIdleWithInitialState() {
        let state = StatsRevampStoreState()
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .idle)
    }

    func testViewsAndVisitorsStatusLoadingWhenAnyStatusIsLoading() {
        var state = StatsRevampStoreState()
        state.summaryStatus = .success
        state.topReferrersStatus = .success
        state.topCountriesStatus = .loading
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .loading)
    }

    func testViewsAndVisitorsStatusSuccessWhenAnyStatusIsSuccess() {
        var state = StatsRevampStoreState()
        state.summaryStatus = .success
        state.topReferrersStatus = .error
        state.topCountriesStatus = .error
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .success)
    }

    func testViewsAndVisitorsStatusErrorWhenAllStatusesAreErrored() {
        var state = StatsRevampStoreState()
        state.summaryStatus = .error
        state.topReferrersStatus = .error
        state.topCountriesStatus = .error
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .error)
    }

    func testViewsAndVisitorsStatusSuccessWhenAllStatusesAreErroredAndCachedDataExist() {
        var state = StatsRevampStoreState()
        state.summaryStatus = .error
        state.summary = StatsSummaryTimeIntervalData(period: .day, unit: .day, periodEndDate: Date(), summaryData: [])
        state.topReferrersStatus = .error
        state.topCountriesStatus = .error
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .success)
    }

    func testViewsAndVisitorsStatusIdleWhenUnrelatedStatusChanged() {
        var state = StatsRevampStoreState()
        state.topPostsAndPagesStatus = .loading
        sut = StatsRevampStore(initialState: state, dispatcher: dispatcher)

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .idle)
    }

    // MARK: - Action Dispatching

    func testRefreshViewsAndVisitorsLoadingState() {
        dispatcher.dispatch(StatsRevampStoreAction.refreshViewsAndVisitors(date: Date()))

        XCTAssertTrue(sut.viewsAndVisitorsStatus == .loading)
    }

    func testRefreshLikesTotalsLoadingState() {
        dispatcher.dispatch(StatsRevampStoreAction.refreshLikesTotals(date: Date()))

        XCTAssertTrue(sut.likesTotalsStatus == .loading)
    }
}
