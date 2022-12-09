import XCTest

@testable import WordPress

final class AppIconListViewModelTests: XCTestCase {

    private var viewModel: AppIconListViewModel!

    // MARK: - Lifecycle

    override func setUp() async throws {
        self.viewModel = AppIconListViewModel()
    }

    // MARK: - Tests

    /// Tests exactly one primary icon exists.
    func testExactlyOnePrimaryIcon() {
        let icons = viewModel.icons
        let primaryIcons = icons.flatMap { $0.items }.filter { $0.isPrimary }
        XCTAssertTrue(primaryIcons.count == 1)
    }

    /// Tests at least one custom icon exists.
    func testAtLeastOneCustomIcon() {
        let icons = viewModel.icons.flatMap { $0.items }.filter { !$0.isPrimary }
        XCTAssertTrue(icons.count >= 1)
    }
}
