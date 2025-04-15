import XCTest
@testable import WordPress

final class JetpackPluginOverlayViewModelTests: XCTestCase {
    let viewModel = JetpackPluginOverlayViewModel(siteName: "https://wordpress.com", plugin: .multiple)

    func testShouldShowCloseButtonIsTrue() {
        XCTAssert(viewModel.shouldShowCloseButton)
    }

    // TODO: - Test Navigation & Tracks API
}
