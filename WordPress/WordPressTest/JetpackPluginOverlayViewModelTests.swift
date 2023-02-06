import XCTest
@testable import WordPress

final class JetpackPluginOverlayViewModelTests: XCTestCase {
    let viewModel = JetpackPluginOverlayViewModel(siteName: "https://wordpress.com")

    func testShouldShowCloseButtonIsTrue() {
        XCTAssert(viewModel.shouldShowCloseButton)
    }

    // TODO: - Test Navigation & Tracks API
}
