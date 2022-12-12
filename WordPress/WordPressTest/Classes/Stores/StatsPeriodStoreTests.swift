import WordPressKit
import WordPressFlux
import XCTest

@testable import WordPress

class StatsPeriodStoreTests: XCTestCase {
    private var dispatcher: ActionDispatcher!
    private var sut: StatsPeriodStore!

    override func setUp() {
        super.setUp()
        dispatcher = ActionDispatcher()
        sut = StatsPeriodStore(dispatcher: dispatcher)
        sut.statsServiceRemote = StatsServiceRemoteV2Mock(wordPressComRestApi: WordPressComRestApi(oAuthToken: nil, userAgent: nil), siteID: 123, siteTimezone: .autoupdatingCurrent)
    }

    override func tearDown() {
        dispatcher = nil
        sut = nil
        super.tearDown()
    }

    func testMarkReferrerAsSpam() {
        guard
            let firstURL = URL(string: "https://www.domain.com/test"),
            let secondURL = URL(string: "https://www.someotherdomain.com/test") else {
            XCTFail("Failed to create URLs")
            return
        }
        let referrerOne = StatsReferrer(title: "A title", viewsCount: 0, url: firstURL, iconURL: nil, children: [])
        let referrerTwo = StatsReferrer(title: "A title", viewsCount: 0, url: secondURL, iconURL: nil, children: [])
        sut.state.topReferrers = .init(period: .month, periodEndDate: Date(), referrers: [referrerOne, referrerTwo], totalReferrerViewsCount: 0, otherReferrerViewsCount: 0)

        sut.toggleSpamState(for: referrerOne.url?.host ?? "", currentValue: referrerOne.isSpam)

        XCTAssertTrue(sut.state.topReferrers!.referrers[0].isSpam)
        XCTAssertFalse(sut.state.topReferrers!.referrers[1].isSpam)
    }

    func testUnmarkReferrerAsSpam() {
        guard
            let firstURL = URL(string: "https://www.domain.com/test"),
            let secondURL = URL(string: "https://www.someotherdomain.com/test") else {
            XCTFail("Failed to create URLs")
            return
        }
        var referrerOne = StatsReferrer(title: "A title", viewsCount: 0, url: firstURL, iconURL: nil, children: [])
        referrerOne.isSpam = true
        let referrerTwo = StatsReferrer(title: "A title", viewsCount: 0, url: secondURL, iconURL: nil, children: [])
        sut.state.topReferrers = .init(period: .month, periodEndDate: Date(), referrers: [referrerOne, referrerTwo], totalReferrerViewsCount: 0, otherReferrerViewsCount: 0)

        sut.toggleSpamState(for: referrerOne.url?.host ?? "", currentValue: referrerOne.isSpam)

        XCTAssertFalse(sut.state.topReferrers!.referrers[0].isSpam)
        XCTAssertFalse(sut.state.topReferrers!.referrers[1].isSpam)
    }

    func testRefreshViewsAndVisitorsLoadingState() {
        dispatcher.dispatch(PeriodAction.refreshViewsAndVisitors(date: Date()))

        XCTAssertTrue(sut.state.summaryStatus == .loading)
        XCTAssertTrue(sut.state.topCountriesStatus == .loading)
        XCTAssertTrue(sut.state.topReferrersStatus == .loading)
    }

    func testRefreshTotalLikesLoadingState() {
        dispatcher.dispatch(PeriodAction.refreshTotalLikes(date: Date()))

        XCTAssertTrue(sut.state.summaryStatus == .loading)
        XCTAssertTrue(sut.state.topPostsAndPagesStatus == .loading)
    }
}

private extension StatsPeriodStoreTests {
    class StatsServiceRemoteV2Mock: StatsServiceRemoteV2 {
        override func toggleSpamState(for referrerDomain: String, currentValue: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
            success()
        }
    }
}
