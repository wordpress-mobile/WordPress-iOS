import XCTest
@testable import WordPress

final class DashboardGoogleDomainsViewModelTests: XCTestCase {
    func testDidShowCardInvokesShownTrack() {
        let mockEventTracker = MockEventTracker()
        let sut = DashboardGoogleDomainsViewModel(tracker: mockEventTracker)

        sut.didShowCard()

        XCTAssertEqual(mockEventTracker.lastFiredEvent, .domainTransferShown)
    }

    func testDidTapTransferInvokesButtonTappedTrack() {
        let mockEventTracker = MockEventTracker()
        let sut = DashboardGoogleDomainsViewModel(tracker: mockEventTracker)

        sut.didTapTransferDomains()

        XCTAssertEqual(mockEventTracker.lastFiredEvent, .domainTransferButtonTapped)
    }

    func testDidTapTransferInvokesWebViewPresentation() {
        let sut = DashboardGoogleDomainsViewModel()
        let cell = MockDashboardGoogleDomainsCard()

        sut.cell = cell
        sut.didTapTransferDomains()

        XCTAssertEqual(cell.presentWebViewCallCount, 1)
    }

    func testDidTapTransferInvokesMoreTappedTrack() {
        let mockEventTracker = MockEventTracker()
        let sut = DashboardGoogleDomainsViewModel(tracker: mockEventTracker)

        sut.didTapMore()

        XCTAssertEqual(mockEventTracker.lastFiredEvent, .domainTransferMoreTapped)
    }
}

private final class MockDashboardGoogleDomainsCard: DashboardGoogleDomainsCardCellProtocol {
    var presentWebViewCallCount = 0

    func presentGoogleDomainsWebView(with url: URL) {
        presentWebViewCallCount += 1
    }
}
