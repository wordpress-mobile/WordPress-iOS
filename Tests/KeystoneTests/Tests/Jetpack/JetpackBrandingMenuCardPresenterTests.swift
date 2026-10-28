import XCTest
@testable import WordPress
@testable import WordPressData

final class JetpackBrandingMenuCardPresenterTests: CoreDataTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase = .normal
    private var savedAppUIType: RootViewCoordinator.AppUIType?
    private var remoteConfigStore = RemoteConfigStoreMock()
    private var currentDateProvider: MockCurrentDateProvider!

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        mockUserDefaults = InMemoryUserDefaults()
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        currentDateProvider = MockCurrentDateProvider()
        let account = AccountBuilder(contextManager.mainContext).build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
        JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType
    }

    func testShouldShowTopCardBasedOnPhase() {
        // Given
        let blog = BlogBuilder(mainContext)
            .withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )

        // Normal phase
        setPhase(phase: .normal)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase One
        setPhase(phase: .one)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase Two
        setPhase(phase: .two)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase Three
        setPhase(phase: .three)
        XCTAssertTrue(presenter.shouldShowTopCard())

        // Phase Four
        setPhase(phase: .four)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase New Users
        setPhase(phase: .newUsers)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Phase Self Hosted
        UserSettings.defaultDotComUUID = nil
        setPhase(phase: .selfHosted)
        XCTAssertTrue(presenter.shouldShowTopCard())
    }

    func testShouldShowBottomCardBasedOnPhase() {
        // Given
        let blog = BlogBuilder(mainContext)
            .withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )

        // Normal phase
        setPhase(phase: .normal)
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase One
        setPhase(phase: .one)
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Two
        setPhase(phase: .two)
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Three
        setPhase(phase: .three)
        XCTAssertFalse(presenter.shouldShowBottomCard())

        // Phase Four
        setPhase(phase: .four)
        XCTAssertTrue(presenter.shouldShowBottomCard())

        // Phase New Users
        setPhase(phase: .newUsers)
        XCTAssertTrue(presenter.shouldShowBottomCard())

        // Phase Self Hosted
        UserSettings.defaultDotComUUID = nil
        setPhase(phase: .selfHosted)
        XCTAssertFalse(presenter.shouldShowBottomCard())
    }

    func testPhaseThreeCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            remoteConfigStore: remoteConfigStore,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )
        setPhase(phase: .three)
        remoteConfigStore.phaseThreeBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(
            config.description,
            "Stats, Reader, Notifications and other features will move to the Jetpack mobile app soon."
        )
        XCTAssertEqual(config.type, .expanded)
    }

    func testPhaseFourCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            remoteConfigStore: remoteConfigStore,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )
        setPhase(phase: .four)

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(config.description, "Switch to Jetpack")
        XCTAssertEqual(config.type, .compact)
    }

    func testPhaseNewUsersCardConfig() throws {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            remoteConfigStore: remoteConfigStore,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )
        setPhase(phase: .newUsers)
        remoteConfigStore.phaseNewUsersBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(
            config.description,
            "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack."
        )
        XCTAssertEqual(config.type, .expanded)
    }

    func testPhaseSelfHostedCardConfig() throws {
        // Given
        UserSettings.defaultDotComUUID = nil
        let blog = BlogBuilder(mainContext)
            .withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: blog,
            remoteConfigStore: remoteConfigStore,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )
        setPhase(phase: .selfHosted)
        remoteConfigStore.phaseSelfHostedBlogPostUrl = "example.com"

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(
            config.description,
            "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack."
        )
        XCTAssertEqual(config.type, .expanded)
    }

    func testHidingTheMenuCard() {
        // Given
        let presenter = JetpackBrandingMenuCardPresenter(
            blog: nil,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults
        )
        setPhase(phase: .three)

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
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults,
            currentDateProvider: currentDateProvider
        )
        setPhase(phase: .three)
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
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults,
            currentDateProvider: currentDateProvider
        )
        setPhase(phase: .three)
        currentDateProvider.dateToReturn = currentDate

        // When
        presenter.remindLaterTapped()
        currentDateProvider.dateToReturn = currentDate.addingTimeInterval(secondsInSevenDays + 1)

        // Then
        XCTAssertTrue(presenter.shouldShowTopCard())
    }

    private func setPhase(phase: JetpackFeaturesRemovalCoordinator.GeneralPhase) {
        self.phase = phase
        // The app sets the UI type from the phase when it builds the root view.
        JetpackFeaturesRemovalCoordinator.currentAppUIType = RootViewCoordinator.appUIType(
            for: phase,
            isReaderInWordPressAppEnabled: false
        )
    }
}
