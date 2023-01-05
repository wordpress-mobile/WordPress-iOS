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
        XCTAssertFalse(presenter.shouldShowCard())
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
        XCTAssertFalse(presenter.shouldShowCard())
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
        XCTAssertTrue(presenter.shouldShowCard())
    }

}

private class MockCurrentDateProvider: CurrentDateProvider {
    var dateToReturn: Date?

    func date() -> Date {
        return dateToReturn ?? Date()
    }
}
