import XCTest

@testable import WordPress
@testable import WordPressData

final class JetpackBrandingMenuCardPresenterTests: CoreDataTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase = .normal
    private var savedAppUIType: RootViewCoordinator.AppUIType?
    private var currentDateProvider: MockCurrentDateProvider!

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        mockUserDefaults = InMemoryUserDefaults()
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        currentDateProvider = MockCurrentDateProvider()
    }

    override func tearDown() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType
    }

    func testShouldShowTopCardBasedOnPhase() {
        // Given
        let presenter = makePresenter(blog: makeJetpackBlog())

        // Normal phase
        setPhase(phase: .normal)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Static screens phase
        setPhase(phase: .staticScreens)
        XCTAssertFalse(presenter.shouldShowTopCard())

        // Self-hosted phase
        setPhase(phase: .selfHosted)
        XCTAssertTrue(presenter.shouldShowTopCard())
    }

    func testTopCardIsHiddenForSitesWithoutJetpack() {
        // Given
        let presenter = makePresenter(blog: BlogBuilder(mainContext).build())
        setPhase(phase: .selfHosted)

        // When & Then
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testSelfHostedCardConfig() throws {
        // Given
        let presenter = makePresenter(blog: makeJetpackBlog())
        setPhase(phase: .selfHosted)

        // When
        let config = try XCTUnwrap(presenter.cardConfig())

        // Then
        XCTAssertEqual(
            config.description,
            "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack."
        )
        XCTAssertEqual(config.type, .expanded)
    }

    func testNoCardConfigOutsideSelfHostedPhase() {
        // Given
        let presenter = makePresenter(blog: makeJetpackBlog())

        // When & Then
        setPhase(phase: .normal)
        XCTAssertNil(presenter.cardConfig())

        setPhase(phase: .staticScreens)
        XCTAssertNil(presenter.cardConfig())
    }

    func testHidingTheMenuCard() {
        // Given
        let presenter = makePresenter(blog: makeJetpackBlog())
        setPhase(phase: .selfHosted)

        // When
        presenter.hideThisTapped()

        // Then
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testRemindMeLaterTappedRecently() {
        // Given
        let secondsInDay = TimeInterval(86_400)
        let currentDate = Date()
        let presenter = makePresenter(blog: makeJetpackBlog())
        setPhase(phase: .selfHosted)
        currentDateProvider.dateToReturn = currentDate

        // When
        presenter.remindLaterTapped()
        currentDateProvider.dateToReturn = currentDate.addingTimeInterval(secondsInDay)

        // Then
        XCTAssertFalse(presenter.shouldShowTopCard())
    }

    func testRemindMeLaterTappedAndIntervalPassed() {
        // Given
        let secondsInFourDays = TimeInterval(86_400 * 4)
        let currentDate = Date()
        let presenter = makePresenter(blog: makeJetpackBlog())
        setPhase(phase: .selfHosted)
        currentDateProvider.dateToReturn = currentDate

        // When
        presenter.remindLaterTapped()
        currentDateProvider.dateToReturn = currentDate.addingTimeInterval(secondsInFourDays + 1)

        // Then
        XCTAssertTrue(presenter.shouldShowTopCard())
    }

    // MARK: Helpers

    private func makeJetpackBlog() -> Blog {
        BlogBuilder(mainContext).withJetpack(version: "5.6", username: "test_user", email: "user@example.com").build()
    }

    private func makePresenter(blog: Blog?) -> JetpackBrandingMenuCardPresenter {
        JetpackBrandingMenuCardPresenter(
            blog: blog,
            phaseProvider: { self.phase },
            persistenceStore: mockUserDefaults,
            currentDateProvider: currentDateProvider
        )
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
