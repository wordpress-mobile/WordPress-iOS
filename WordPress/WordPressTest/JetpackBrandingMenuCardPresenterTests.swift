import XCTest
@testable import WordPress

final class JetpackBrandingMenuCardPresenterTests: CoreDataTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var remoteFeatureFlagsStore = RemoteFeatureFlagStoreMock()
    private var remoteConfigStore = RemoteConfigStoreMock()
    private var currentDateProvider: MockCurrentDateProvider!

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        mockUserDefaults = InMemoryUserDefaults()
        currentDateProvider = MockCurrentDateProvider()
        let account = AccountBuilder(contextManager).build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
    }

    func testShouldShowTopCardBasedOnPhase() {
        // Given
        let blog = BlogBuilder(mainContext).withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
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

        // Phase Self Hosted
        UserSettings.defaultDotComUUID = nil
        remoteFeatureFlagsStore.removalPhaseSelfHosted = true
        XCTAssertTrue(presenter.shouldShowTopCard())
    }

    func testShouldShowBottomCardBasedOnPhase() {
        // Given
        let blog = BlogBuilder(mainContext).withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)

        // Normal phase
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase One
        remoteFeatureFlagsStore.removalPhaseOne = true
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Two
        remoteFeatureFlagsStore.removalPhaseTwo = true
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Three
        remoteFeatureFlagsStore.removalPhaseThree = true
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Four
        remoteFeatureFlagsStore.removalPhaseFour = true
        XCTAssertTrue(presenter.shouldShowBottomCard())

        // Phase New Users
        remoteFeatureFlagsStore.removalPhaseNewUsers = true
        XCTAssertTrue(presenter.shouldShowBottomCard())

        // Phase Self Hosted
        UserSettings.defaultDotComUUID = nil
        remoteFeatureFlagsStore.removalPhaseSelfHosted = true
        XCTAssertFalse(presenter.shouldShowBottomCard())
    }

    func testPhaseThreeCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
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
        XCTAssertEqual(config.type, .expanded)
    }

    func testPhaseFourCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            remoteConfigStore: remoteConfigStore,
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)
        remoteFeatureFlagsStore.removalPhaseFour = true

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(config.description, "Switch to Jetpack")
        XCTAssertNil(config.learnMoreButtonURL)
        XCTAssertEqual(config.type, .compact)
    }

    func testPhaseNewUsersCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            remoteConfigStore: remoteConfigStore,
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)
        remoteFeatureFlagsStore.removalPhaseNewUsers = true
        remoteConfigStore.phaseNewUsersBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(config.description, "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack.")
        XCTAssertEqual(config.learnMoreButtonURL, "example.com")
        XCTAssertEqual(config.type, .expanded)
    }

    func testPhaseSelfHostedCardConfig() throws {
        // Given
        UserSettings.defaultDotComUUID = nil
        let blog = BlogBuilder(mainContext).withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
            remoteConfigStore: remoteConfigStore,
            featureFlagStore: remoteFeatureFlagsStore,
            persistenceStore: mockUserDefaults)
        remoteFeatureFlagsStore.removalPhaseSelfHosted = true
        remoteConfigStore.phaseSelfHostedBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(config.description, "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack.")
        XCTAssertEqual(config.learnMoreButtonURL, "example.com")
        XCTAssertEqual(config.type, .expanded)
    }

    func testHidingTheMenuCard() {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
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
            blog: nil,
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
            blog: nil,
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
