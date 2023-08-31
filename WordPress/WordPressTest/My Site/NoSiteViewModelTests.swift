import XCTest
@testable import WordPress

final class NoSiteViewModelTests: CoreDataTestCase {

    func test_simplifiedAppUIType_showsAccountAndSettings() {
        // Given
        let viewModel = NoSitesViewModel(appUIType: .simplified, account: nil)

        // When & Then
        XCTAssertEqual(viewModel.isShowingAccountAndSettings, true)
    }

    func test_staticScreenAppUIType_hidesAccountAndSettings() {
        // Given
        let viewModel = NoSitesViewModel(appUIType: .staticScreens, account: nil)

        // When & Then
        XCTAssertEqual(viewModel.isShowingAccountAndSettings, false)
    }

    func test_normalAppUIType_hidesAccountAndSettings() {
        // Given
        let viewModel = NoSitesViewModel(appUIType: .normal, account: nil)

        // When & Then
        XCTAssertEqual(viewModel.isShowingAccountAndSettings, false)
    }

    func test_gravatarURLIsNil_WhenAccountIsNil() {
        // Given
        let viewModel = NoSitesViewModel(appUIType: nil, account: nil)

        // When & Then
        XCTAssertNil(viewModel.gravatarURL)
    }

    func test_gravatarURLIsNotNil_WhenAccountIsNotNil() {
        // Given
        let account = AccountBuilder(contextManager)
            .with(email: "account@email.com")
            .build()
        let viewModel = NoSitesViewModel(appUIType: nil, account: account)

        // When & Then
        XCTAssertNotNil(viewModel.gravatarURL)
    }

    func test_displayNameIsDash_WhenAccountIsNil() {
        // Given
        let viewModel = NoSitesViewModel(appUIType: nil, account: nil)

        // When & Then
        XCTAssertEqual(viewModel.displayName, "-")
    }

    func test_displayNameIsAccountDisplayName_WhenAccountIsNotNil() {
        // Given
        let account = AccountBuilder(contextManager)
            .with(email: "account@email.com")
            .with(displayName: "Test")
            .build()
        let viewModel = NoSitesViewModel(appUIType: nil, account: account)

        // When & Then
        XCTAssertEqual(viewModel.displayName, account.displayName)
    }
}
