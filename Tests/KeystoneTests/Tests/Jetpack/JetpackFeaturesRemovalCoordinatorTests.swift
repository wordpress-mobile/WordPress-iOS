import XCTest
import BuildSettingsKit
@testable import WordPress
@testable import WordPressData

final class JetpackFeaturesRemovalCoordinatorTests: CoreDataTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        mockUserDefaults = InMemoryUserDefaults()
        let account = AccountBuilder(contextManager.mainContext).with(username: "test-account-JetpackFeaturesRemovalCoordinatorTests").build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
        JetpackFeaturesRemovalCoordinator.currentAppUIType = nil
    }

    // MARK: General Phase Tests

    func testNormalGeneralPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testReturnNormalPhaseForLoggedOutUsers() {
        // Given
        UserSettings.defaultDotComUUID = nil
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testNewUsersGeneralPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: true, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .newUsers)
    }

    func testNewUsersGeneralPhasePrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: true, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .newUsers)
    }

    func testSelfHostedGeneralPhase() {
        // Given
        UserSettings.defaultDotComUUID = nil
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: true)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .selfHosted)
    }

    func testGeneralPhaseIfSelfHostedIsEnabledWhileLoggedIn() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: true)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)
    }

    func testGeneralPhaseOne() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)
    }

    func testGeneralPhaseTwo() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testGeneralPhaseTwoPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testGeneralPhaseThree() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: true, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .three)
    }

    func testGeneralPhaseThreePrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .three)
    }

    func testGeneralPhaseFour() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .four)
    }

    func testGeneralPhaseFourPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .four)
    }

    // MARK: Site Creation Phase Tests

    func testNormalSiteCreationPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testSiteCreationPhaseOne() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        remote.flags = flags
        store.update(using: remote, waitOn: self)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: true, phaseFour: false, phaseNewUsers: false, phaseSelfHosted: false)
        remote.flags = flags
        store.update(using: remote, waitOn: self)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)
    }

    func testSiteCreationPhaseTwo() throws {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
        _ = BlogBuilder(mainContext).build()
        try mainContext.save()
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)
        // Then
        XCTAssertEqual(phase, .two)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: true, phaseSelfHosted: false)
        remote.flags = flags
        store.update(using: remote, waitOn: self)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testSiteCreationPhaseNormalWhenUserHasNoBlog() throws {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)
        // Then
        XCTAssertEqual(phase, .normal)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: true, phaseSelfHosted: false)
        remote.flags = flags
        store.update(using: remote, waitOn: self)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testSiteCreationPhaseTwoPrecedence() throws {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
        _ = BlogBuilder(mainContext).build()
        try mainContext.save()
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)

        // When
        flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: false, phaseNewUsers: true, phaseSelfHosted: false)
        remote.flags = flags
        store.update(using: remote, waitOn: self)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    // MARK: Removal Deadline

    func testFetchingRemovalDeadline() {
        // Given
        let remoteConfigStore = RemoteConfigStore(persistenceStore: mockUserDefaults)
        mockUserDefaults.set(["jp_deadline": "2022-10-10"], forKey: RemoteConfigStore.Constants.CachedResponseKey)

        // When
        let deadline = JetpackFeaturesRemovalCoordinator.removalDeadline(remoteConfigStore: remoteConfigStore)

        XCTAssertEqual(deadline?.components.year, 2022)
        XCTAssertEqual(deadline?.components.month, 10)
        XCTAssertEqual(deadline?.components.day, 10)
    }

    func testRemovalDeadlineDoesNotExist() {
        // Given
        let remoteConfigStore = RemoteConfigStore(persistenceStore: mockUserDefaults)

        // When
        let deadline = JetpackFeaturesRemovalCoordinator.removalDeadline(remoteConfigStore: remoteConfigStore)

        XCTAssertNil(deadline)
    }

    // MARK: Offline Scenarios

    func testWordPressOfflineState() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        // assume that the user fails to request for remote feature flags and we fall back to the default values.
        let remote = MockFeatureFlagRemote()
        store.update(using: remote, waitOn: self)

        // When
        // assume that we're requesting from the WordPress app.
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store, app: .wordpress)

        // Then
        XCTAssertEqual(phase, .staticScreens)
    }

    func testJetpackOfflineState() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        // assume that the user fails to request for remote feature flags and we fall back to the default values.
        let remote = MockFeatureFlagRemote()
        store.update(using: remote, waitOn: self)

        // When
        // assume that we're requesting from the Jetpack app.
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store, app: .jetpack)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    // MARK: App UI Type

    func testReaderTabsUITypeInEveryPhaseWhenFlagIsOn() {
        for (phase, flags) in allPhaseFlags() {
            // When
            let store = makeCoordinator(flags: flags, app: .wordpress, isReaderAndNotificationsEnabled: true)

            // Then
            XCTAssertEqual(
                JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store, app: .wordpress),
                phase
            )
            XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .readerTabs, "phase \(phase)")
            XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled(), "phase \(phase)")
            XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures(), "phase \(phase)")
            XCTAssertTrue(JetpackFeaturesRemovalCoordinator.readerAndNotificationsAvailable(), "phase \(phase)")
            XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderTabsUI(), "phase \(phase)")
        }
    }

    func testPhaseMappingIsUnchangedWhenFlagIsOff() {
        let expectedTypes: [JetpackFeaturesRemovalCoordinator.GeneralPhase: RootViewCoordinator.AppUIType] = [
            .normal: .normal,
            .one: .normal,
            .two: .normal,
            .three: .normal,
            .staticScreens: .staticScreens,
            .four: .simplified,
            .newUsers: .simplified
        ]
        for (phase, flags) in allPhaseFlags() {
            // When
            makeCoordinator(flags: flags, app: .wordpress, isReaderAndNotificationsEnabled: false)

            // Then
            XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, expectedTypes[phase], "phase \(phase)")
            XCTAssertFalse(JetpackFeaturesRemovalCoordinator.isReaderTabsUI(), "phase \(phase)")
        }
    }

    func testStaticScreensPhaseWhenFlagIsOff() {
        // When
        makeCoordinator(
            flags: productionFlags(),
            app: .wordpress,
            isReaderAndNotificationsEnabled: false
        )

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .staticScreens)
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures())
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.readerAndNotificationsAvailable())
    }

    func testSelfHostedPhaseWithoutAccount() {
        // Given
        UserSettings.defaultDotComUUID = nil
        let flags = productionFlags()

        for isReaderAndNotificationsEnabled in [true, false] {
            // When
            makeCoordinator(
                flags: flags,
                app: .wordpress,
                isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
            )

            // Then
            XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .simplified)
            XCTAssertFalse(JetpackFeaturesRemovalCoordinator.readerAndNotificationsAvailable())
        }
    }

    func testNormalUITypeWithoutAccountWhenSelfHostedPhaseIsOff() {
        // Given
        UserSettings.defaultDotComUUID = nil
        let flags = productionFlags(phaseSelfHosted: false)

        // When
        makeCoordinator(flags: flags, app: .wordpress, isReaderAndNotificationsEnabled: true)

        // Then
        XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)
    }

    func testJetpackAppIgnoresFlag() {
        let flags = productionFlags()

        for isReaderAndNotificationsEnabled in [true, false] {
            // When
            makeCoordinator(
                flags: flags,
                app: .jetpack,
                isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
            )

            // Then
            XCTAssertEqual(JetpackFeaturesRemovalCoordinator.currentAppUIType, .normal)
            XCTAssertTrue(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
            XCTAssertTrue(JetpackFeaturesRemovalCoordinator.readerAndNotificationsAvailable())
        }
    }

    func testJetpackBrandingIsHiddenInReaderTabsUI() {
        // Given
        let flags = productionFlags()

        // When
        makeCoordinator(flags: flags, app: .wordpress, isReaderAndNotificationsEnabled: true)

        // Then
        XCTAssertFalse(
            JetpackBrandingVisibility.all.isEnabled(
                isWordPress: true,
                isDotComAvailable: true,
                shouldShowJetpackFeatures: JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures(),
                isReaderTabsUI: JetpackFeaturesRemovalCoordinator.isReaderTabsUI()
            )
        )
    }

    // MARK: Helpers

    /// Remote flags that resolve to each general phase for a WordPress.com account.
    private func allPhaseFlags() -> [(JetpackFeaturesRemovalCoordinator.GeneralPhase, [WordPressKit.FeatureFlag])] {
        [
            (
                .normal,
                generateFlags(
                    phaseOne: false,
                    phaseTwo: false,
                    phaseThree: false,
                    phaseFour: false,
                    phaseNewUsers: false,
                    phaseSelfHosted: false
                )
            ),
            (
                .one,
                generateFlags(
                    phaseOne: true,
                    phaseTwo: false,
                    phaseThree: false,
                    phaseFour: false,
                    phaseNewUsers: false,
                    phaseSelfHosted: false
                )
            ),
            (
                .two,
                generateFlags(
                    phaseOne: true,
                    phaseTwo: true,
                    phaseThree: false,
                    phaseFour: false,
                    phaseNewUsers: false,
                    phaseSelfHosted: false
                )
            ),
            (
                .three,
                generateFlags(
                    phaseOne: true,
                    phaseTwo: true,
                    phaseThree: true,
                    phaseFour: false,
                    phaseNewUsers: false,
                    phaseSelfHosted: false
                )
            ),
            (.staticScreens, productionFlags()),
            (
                .four,
                generateFlags(
                    phaseOne: true,
                    phaseTwo: true,
                    phaseThree: true,
                    phaseFour: true,
                    phaseNewUsers: false,
                    phaseSelfHosted: false
                )
            ),
            (
                .newUsers,
                generateFlags(
                    phaseOne: true,
                    phaseTwo: true,
                    phaseThree: true,
                    phaseFour: true,
                    phaseNewUsers: true,
                    phaseSelfHosted: false
                )
            )
        ]
    }

    /// The removal phase flags observed in production on 2026-09-25: signed-in users are in the
    /// static screens phase, and users without a WordPress.com account in the self-hosted phase.
    private func productionFlags(phaseSelfHosted: Bool = true) -> [WordPressKit.FeatureFlag] {
        generateFlags(
            phaseOne: true,
            phaseTwo: true,
            phaseThree: true,
            phaseFour: false,
            phaseStaticScreens: true,
            phaseNewUsers: false,
            phaseSelfHosted: phaseSelfHosted
        )
    }

    @discardableResult
    private func makeCoordinator(
        flags: [WordPressKit.FeatureFlag],
        app: AppBrand,
        isReaderAndNotificationsEnabled: Bool
    ) -> RemoteFeatureFlagStore {
        let store = RemoteFeatureFlagStore(persistenceStore: InMemoryUserDefaults())
        store.update(using: MockFeatureFlagRemote(flags: flags), waitOn: self)
        _ = RootViewCoordinator(
            featureFlagStore: store,
            windowManager: nil,
            app: app,
            isReaderAndNotificationsEnabled: isReaderAndNotificationsEnabled
        )
        return store
    }

    private func generateFlags(phaseOne: Bool,
                               phaseTwo: Bool,
                               phaseThree: Bool,
                               phaseFour: Bool,
                               phaseStaticScreens: Bool = false,
                               phaseNewUsers: Bool,
                               phaseSelfHosted: Bool) -> [WordPressKit.FeatureFlag] {
        return [
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseOne.remoteKey, value: phaseOne),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseTwo.remoteKey, value: phaseTwo),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseThree.remoteKey, value: phaseThree),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseFour.remoteKey, value: phaseFour),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalStaticPosters.remoteKey, value: phaseStaticScreens),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseNewUsers.remoteKey, value: phaseNewUsers),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseSelfHosted.remoteKey, value: phaseSelfHosted),
        ]
    }
}

private extension Date {
    var components: DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                               from: self)
    }
}

internal extension RemoteFeatureFlagStore {
    func update(using remote: FeatureFlagRemote, waitOn test: XCTestCase) {
        let exp = test.expectation(description: "Store finishes update")
        update(using: remote) {
            exp.fulfill()
        }
        test.wait(for: [exp], timeout: 1)
    }
}
