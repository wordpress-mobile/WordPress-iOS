
import XCTest

@testable import WordPress

final class CompliancePopoverCoordinatorTests: XCTestCase {

    private var service: ComplianceLocationServiceMock!
    private var defaults: UserDefaultsMock!
    private var coordinator: CompliancePopoverCoordinator!

    override func setUp() {
        self.service = .init()
        self.defaults = .init()
        self.coordinator = .init(
            defaults: defaults,
            complianceService: service,
            isFeatureFlagEnabled: true
        )
    }

    // MARK: - Tests

    func testPopoverIsShown() {
        // Given
        let expectation = expectation(description: "Should display popover")
        self.defaults.didShowCompliancePopupOverride = false

        // When
        self.coordinator.presentIfNeeded { shown in
            XCTAssertTrue(shown)
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1)
    }

    func testPopoverIsNotShownWhenShownBefore() {
        // Given
        let expectation = expectation(description: "Should not display popover")
        self.defaults.didShowCompliancePopupOverride = true

        // When
        coordinator.presentIfNeeded { shown in
            XCTAssertFalse(shown)
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1)
    }

    func testPopoverIsNotShownForNonEUCountry() {
        // Given
        let expectation = expectation(description: "Should not display popover for non-EU country")
        self.service.countryCode = "MA"
        self.defaults.didShowCompliancePopupOverride = true

        // When
        coordinator.presentIfNeeded { shown in
            XCTAssertFalse(shown)
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Helpers

    private func makeCoordinator(
        service: ComplianceLocationService = ComplianceLocationServiceMock(),
        didShowCompliancePopup: Bool = false,
        isFeatureFlagEnabled: Bool = true
    ) -> CompliancePopoverCoordinator {
        let defaults = UserDefaultsMock()
        defaults.didShowCompliancePopupOverride = didShowCompliancePopup
        return .init(
            defaults: defaults,
            complianceService: service,
            isFeatureFlagEnabled: isFeatureFlagEnabled
        )
    }

}

// MARK: - Mocks

private class ComplianceLocationServiceMock: ComplianceLocationService {

    var countryCode = "DE"

    override func getIPCountryCode(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(countryCode))
    }
}

private class UserDefaultsMock: UserDefaults {

    var didShowCompliancePopupOverride: Bool = false

    override func bool(forKey defaultName: String) -> Bool {
        if defaultName == UserDefaults.didShowCompliancePopupKey {
            return didShowCompliancePopupOverride
        }
        return super.bool(forKey: defaultName)
    }
}
