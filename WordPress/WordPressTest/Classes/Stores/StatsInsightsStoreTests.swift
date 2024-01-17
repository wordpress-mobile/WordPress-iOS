import XCTest
@testable import WordPress

final class StatsInsightsStoreTests: XCTestCase {

    private var sut: StatsInsightsStore!

    override func setUpWithError() throws {
        sut = StatsInsightsStore()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - FollowersTotalsStatusShouldBeIdle

    func testFollowersTotalsStatusStatusShouldBeIdleByDefault() throws {
        XCTAssertEqual(sut.followersTotalsStatus, .idle)
    }

    func testFollowersTotalsStatusStatusShouldBeIdleWhenEmailFollowersStatusIdleDotComFollowersStatusSuccess() throws {
        sut.state.dotComFollowersStatus = .success
        sut.state.emailFollowersStatus = .idle
        XCTAssertEqual(sut.followersTotalsStatus, .idle)
    }

    func testFollowersTotalsStatusStatusShouldBeIdleWhenEmailFollowersStatusSuccessDotComFollowersStatusIdle() throws {
        sut.state.dotComFollowersStatus = .idle
        sut.state.emailFollowersStatus = .success
        XCTAssertEqual(sut.followersTotalsStatus, .idle)
    }

    // MARK: - FollowersTotalsStatusShouldBeLoading

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenDotComFollowersStatusLoading() throws {
        sut.state.dotComFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusLoading() throws {
        sut.state.emailFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusIdleDotComFollowersStatusLoading() throws {
        sut.state.dotComFollowersStatus = .loading
        sut.state.emailFollowersStatus = .idle
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusLoadingDotComFollowersStatusIdle() throws {
        sut.state.dotComFollowersStatus = .idle
        sut.state.emailFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusLoadingDotComFollowersStatusLoading() throws {
        sut.state.dotComFollowersStatus = .loading
        sut.state.emailFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusErrorDotComFollowersStatusLoading() throws {
        sut.state.dotComFollowersStatus = .loading
        sut.state.emailFollowersStatus = .error
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusLoadingDotComFollowersStatusError() throws {
        sut.state.dotComFollowersStatus = .error
        sut.state.emailFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusSuccessDotComFollowersStatusLoading() throws {
        sut.state.dotComFollowersStatus = .loading
        sut.state.emailFollowersStatus = .success
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    func testFollowersTotalsStatusStatusShouldBeLoadingWhenEmailFollowersStatusLoadingDotComFollowersStatusSuccess() throws {
        sut.state.dotComFollowersStatus = .success
        sut.state.emailFollowersStatus = .loading
        XCTAssertEqual(sut.followersTotalsStatus, .loading)
    }

    // MARK: - FollowersTotalsStatusShouldBeError

    func testFollowersTotalsStatusStatusShouldBeErrorWhenEmailFollowersStatusErrorDotComFollowersStatusSuccess() throws {
        sut.state.dotComFollowersStatus = .success
        sut.state.emailFollowersStatus = .error
        XCTAssertEqual(sut.followersTotalsStatus, .error)
    }

    func testFollowersTotalsStatusStatusShouldBeErrorWhenEmailFollowersStatusSuccessDotComFollowersStatusError() throws {
        sut.state.dotComFollowersStatus = .error
        sut.state.emailFollowersStatus = .success
        XCTAssertEqual(sut.followersTotalsStatus, .error)
    }

    func testFollowersTotalsStatusStatusShouldBeErrorWhenEmailFollowersStatusErrorDotComFollowersStatusIdle() throws {
        sut.state.dotComFollowersStatus = .idle
        sut.state.emailFollowersStatus = .error
        XCTAssertEqual(sut.followersTotalsStatus, .error)
    }

    func testFollowersTotalsStatusStatusShouldBeErrorWhenEmailFollowersStatusIdleDotComFollowersStatusError() throws {
        sut.state.dotComFollowersStatus = .error
        sut.state.emailFollowersStatus = .idle
        XCTAssertEqual(sut.followersTotalsStatus, .error)
    }

    // MARK: - FollowersTotalsStatusShouldBeSuccess

    func testFollowersTotalsStatusStatusShouldBeSuccessWhenEmailFollowersStatusSuccessDotComFollowersStatusSuccess() throws {
        sut.state.dotComFollowersStatus = .success
        sut.state.emailFollowersStatus = .success
        XCTAssertEqual(sut.followersTotalsStatus, .success)
    }

}
