import XCTest
@testable import WordPress

final class JetpackBrandingTextProviderTests: CoreDataTestCase {

    // MARK: Private Variables

    private var remoteFeatureFlagsStore: RemoteFeatureFlagStoreMock!
    private var remoteConfigStore = RemoteConfigStoreMock()
    private var currentDateProvider: MockCurrentDateProvider!
    private var removalDeadline: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: "2022-10-10") ?? Date()
    }

    // MARK: Setup

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        remoteFeatureFlagsStore = RemoteFeatureFlagStoreMock()
        currentDateProvider = MockCurrentDateProvider()
        remoteConfigStore.removalDeadline = "2022-10-10"
        let account = AccountBuilder(contextManager).build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
    }

    // MARK: Tests

    func testNormalPhaseText() {
        // Given
        let provider = JetpackBrandingTextProvider(screen: MockBrandedScreen.defaultScreen, featureFlagStore: remoteFeatureFlagsStore)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseOneText() {
        // Given
        let provider = JetpackBrandingTextProvider(screen: MockBrandedScreen.defaultScreen, featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseOne = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseTwoText() {
        // Given
        let provider = JetpackBrandingTextProvider(screen: MockBrandedScreen.defaultScreen, featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseTwo = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Get the Jetpack app")
    }

    func testDefaultText() {
        // Given
        let provider = JetpackBrandingTextProvider(screen: MockBrandedScreen.defaultScreen, featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseFour = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseThreeWithNoFeatureNameShouldReturnDefaultText() {
        // Given
        let screen = MockBrandedScreen(featureName: nil, isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseThreeWithDeadlinePassed() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, months: -1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }


    func testPhaseThreeWithNoDeadlineAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        remoteConfigStore.removalDeadline = nil

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving soon")
    }

    func testPhaseThreeWithNoDeadlineAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        remoteConfigStore.removalDeadline = nil

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving soon")
    }

    func testPhaseThreeWithDeadlineOneMonthAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, months: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving soon")
    }

    func testPhaseThreeWithDeadlineOneMonthAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, months: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving soon")
    }

    func testPhaseThreeWithDeadlineMultipleMonthsAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, months: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving soon")
    }

    func testPhaseThreeWithDeadlineMultipleMonthsAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, months: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving soon")
    }

    func testPhaseThreeWithDeadlineOneWeekAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, weeks: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving in 1 week")
    }

    func testPhaseThreeWithDeadlineOneWeekAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, weeks: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving in 1 week")
    }

    func testPhaseThreeWithDeadlineMultipleWeeksAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, weeks: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving in 2 weeks")
    }

    func testPhaseThreeWithDeadlineMultipleWeeksAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, weeks: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving in 2 weeks")
    }

    func testPhaseThreeWithDeadlineOneDayAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving in 1 day")
    }

    func testPhaseThreeWithDeadlineOneDayAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 1)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving in 1 day")
    }

    func testPhaseThreeWithDeadlineMultipleDaysAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving in 2 days")
    }

    func testPhaseThreeWithDeadlineMultipleDaysAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 2)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving in 2 days")
    }

    func testPhaseThreeWithDeadlineLessThanADayAwayAndFeatureIsPlural() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: true, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 0)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature are moving in 1 day")
    }

    func testPhaseThreeWithDeadlineLessThanADayAwayAndFeatureIsSingular() {
        // Given
        let screen = MockBrandedScreen(featureName: "Feature", isPlural: false, analyticsId: "")
        let provider = JetpackBrandingTextProvider(screen: screen,
                                                   featureFlagStore: remoteFeatureFlagsStore,
                                                   remoteConfigStore: remoteConfigStore,
                                                   currentDateProvider: currentDateProvider)
        remoteFeatureFlagsStore.removalPhaseThree = true
        currentDateProvider.dateToReturn = dateBefore(removalDeadline, days: 0)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Feature is moving in 1 day")
    }
}

// MARK: Helpers

private extension JetpackBrandingTextProviderTests {
    struct MockBrandedScreen: JetpackBrandedScreen {
        let featureName: String?
        let isPlural: Bool
        let analyticsId: String

        static var defaultScreen: MockBrandedScreen = .init(featureName: "Feature",
                                                            isPlural: false,
                                                            analyticsId: "")
    }

    enum Constants {
        static let secondsInDay = 86_400
    }

    private func dateBefore(_ date: Date,
                            months: Int = 0,
                            weeks: Int = 0,
                            days: Int = 0) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(month: -months, day: -days, second: -1, weekOfYear: -weeks)
        let newDate = calendar.date(byAdding: components, to: date)
        return newDate ?? date
    }
}
