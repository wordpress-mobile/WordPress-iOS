import XCTest
@testable import WordPress

final class JetpackBrandingMenuCardPresenterTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var remoteFeatureFlagsStore = RemoteFeatureFlagStoreMock()
    private var remoteConfigStore = RemoteConfigStoreMock()
    private var currentDateProvider: MockCurrentDateProvider!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
        currentDateProvider = MockCurrentDateProvider()
    }

    func testShouldShowTopCardBasedOnPhase() {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)

        // Normal phase
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase One
        remoteFeatureFlagsStore.removalPhaseOne = true
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase Two
        remoteFeatureFlagsStore.removalPhaseTwo = true
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase Three
        remoteFeatureFlagsStore.removalPhaseThree = true
        XCTAssertTrue(presenter.shouldShowTopCard())

        // Phase Four
        remoteFeatureFlagsStore.removalPhaseFour = true
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase New Users
        remoteFeatureFlagsStore.removalPhaseNewUsers = true
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testPhaseThreeCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            remoteConfigStore: remoteConfigStore,
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)
        remoteFeatureFlagsStore.removalPhaseThree = true
        remoteConfigStore.phaseThreeBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(config.description, "Stats, Reader, Notifications and other features will move to the Jetpack mobile app soon.")
        XCTAssertEqual(config.learnMoreButtonURL, "example.com")
    }

    func testHidingTheMenuCard() {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)
        remoteFeatureFlagsStore.removalPhaseThree = true

        // When
        presenter.hideThisTapped()

        // Then
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testRemindMeLaterTappedRecently() {
        // Given
        let secondsInDay = TimeInterval(86_400)
        let currentDate = Date()
        let presenter = JetpackBrandingMenuCardPresenter(
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults,
            currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = currentDate

        // When
        presenter.remindLaterTapped()
        currentDateProvider.dateToReturn = currentDate.addingTimeInterval(secondsInDay)

        // Then
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testRemindMeLaterTappedAndIntervalPassed() {
        // Given
        let secondsInSevenDays = TimeInterval(86_400 * 4)
        let currentDate = Date()
        let presenter = JetpackBrandingMenuCardPresenter(
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults,
            currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = currentDate

        // When
        presenter.remindLaterTapped()
        currentDateProvider.dateToReturn = currentDate.addingTimeInterval(secondsInSevenDays + 1)

        // Then
        XCTAssertTrue(presenter.shouldShowTopCard())
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

private class RemoteConfigStoreMock: RemoteConfigStore {

    var phaseThreeBlogPostUrl: String?

    override func value(for key: String) -> Any? {
        if key == "phase_three_blog_post" {
            return phaseThreeBlogPostUrl
        }
        return super.value(for: key)
    }
}

private class MockCurrentDateProvider: CurrentDateProvider {
    var dateToReturn: Date?

    func date() -> Date {
        return dateToReturn ?? Date()
    }
}
