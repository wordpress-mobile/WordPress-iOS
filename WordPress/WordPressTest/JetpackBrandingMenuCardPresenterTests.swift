import XCTest
@testable import WordPress

final class JetpackBrandingMenuCardPresenterTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var remoteFeatureFlagsStore = RemoteFeatureFlagStoreMock()

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
    }

    func testShouldShowCardBasedOnPhase() {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)

        // Normal phase
        XCTAssertFalse(presenter.shouldShowCard())

        // Phase One
        remoteFeatureFlagsStore.removalPhaseOne = true
        XCTAssertFalse(presenter.shouldShowCard())

        // Phase Two
        remoteFeatureFlagsStore.removalPhaseTwo = true
        XCTAssertFalse(presenter.shouldShowCard())

        // Phase Three
        remoteFeatureFlagsStore.removalPhaseThree = true
        XCTAssertTrue(presenter.shouldShowCard())

        // Phase Four
        remoteFeatureFlagsStore.removalPhaseFour = true
        XCTAssertFalse(presenter.shouldShowCard())

        // Phase New Users
        remoteFeatureFlagsStore.removalPhaseNewUsers = true
        XCTAssertFalse(presenter.shouldShowCard())
    }
}

private class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {

    var removalPhaseOne = false
    var removalPhaseTwo = false
    var removalPhaseThree = false
    var removalPhaseFour = false
    var removalPhaseNewUsers = false

    override func value(for flag: OverrideableFlag) -> Bool {
        guard let flag = flag as? WordPress.FeatureFlag else {
            return false
        }
        switch flag {
        case .jetpackFeaturesRemovalPhaseOne:
            return removalPhaseOne
        case .jetpackFeaturesRemovalPhaseTwo:
            return removalPhaseTwo
        case .jetpackFeaturesRemovalPhaseThree:
            return removalPhaseThree
        case .jetpackFeaturesRemovalPhaseFour:
            return removalPhaseFour
        case .jetpackFeaturesRemovalPhaseNewUsers:
            return removalPhaseNewUsers
        default:
            return super.value(for: flag)
        }
    }
}
