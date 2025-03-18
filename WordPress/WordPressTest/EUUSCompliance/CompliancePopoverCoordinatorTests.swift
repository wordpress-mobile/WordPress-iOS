
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

    func testPopoverIsShown() async {
        // Given
        self.defaults.didShowCompliancePopupOverride = false

        // When
        let presented = await coordinator.presentIfNeeded()

        // Then
        XCTAssertTrue(presented)
    }

    func testPopoverIsNotShownWhenShownBefore() async {
        // Given
        self.defaults.didShowCompliancePopupOverride = true

        // When
        let presented = await coordinator.presentIfNeeded()

        // Then
        XCTAssertFalse(presented)
    }

    func testPopoverIsNotShownForNonEUCountry() async {
        // Given
        self.service.countryCode = "MA"
        self.defaults.didShowCompliancePopupOverride = true

        // When
        let presented = await coordinator.presentIfNeeded()

        // Then
        XCTAssertFalse(presented)
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
