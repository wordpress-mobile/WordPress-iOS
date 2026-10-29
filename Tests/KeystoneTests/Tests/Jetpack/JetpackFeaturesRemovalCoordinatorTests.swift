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

    func testAppUITypeForEachPhase() {
        for (phase, flags, withFlagOff, withFlagOn) in allPhaseFlags() {
            let store = makeStore(flags: flags)

            XCTAssertEqual(appUIType(store: store, isReaderInWordPressAppEnabled: false), withFlagOff, "phase \(phase)")
            XCTAssertEqual(appUIType(store: store, isReaderInWordPressAppEnabled: true), withFlagOn, "phase \(phase)")
        }
    }

    func testSelfHostedPhaseWithoutAccountIsSimplified() {
        UserSettings.defaultDotComUUID = nil
        let store = makeStore(flags: productionFlags())

        XCTAssertEqual(appUIType(store: store, isReaderInWordPressAppEnabled: false), .simplified)
        XCTAssertEqual(appUIType(store: store, isReaderInWordPressAppEnabled: true), .simplified)
    }

    func testNormalUITypeWithoutAccountWhenSelfHostedPhaseIsOff() {
        UserSettings.defaultDotComUUID = nil
        let store = makeStore(flags: productionFlags(phaseSelfHosted: false))

        XCTAssertEqual(appUIType(store: store, isReaderInWordPressAppEnabled: true), .normal)
    }

    func testJetpackAppIgnoresFlag() {
        let store = makeStore(flags: productionFlags())

        XCTAssertEqual(appUIType(store: store, app: .jetpack, isReaderInWordPressAppEnabled: false), .normal)
        XCTAssertEqual(appUIType(store: store, app: .jetpack, isReaderInWordPressAppEnabled: true), .normal)
    }

    func testStaticScreensWithReaderKeepsJetpackFeaturesDisabled() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreensWithReader

        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.isReaderAvailable())
    }

    func testStaticScreensUIKeepsReaderUnavailable() {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .staticScreens

        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled())
        XCTAssertTrue(JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures())
        XCTAssertFalse(JetpackFeaturesRemovalCoordinator.isReaderAvailable())
    }

    // MARK: Helpers

    /// Remote flags that resolve to each general phase for a WordPress.com account, with the app
    /// UI type the phase resolves to while the `readerInWordPressApp` flag is off and on.
    private func allPhaseFlags() -> [(
        phase: JetpackFeaturesRemovalCoordinator.GeneralPhase,
        flags: [WordPressKit.FeatureFlag],
        withFlagOff: RootViewCoordinator.AppUIType,
        withFlagOn: RootViewCoordinator.AppUIType
    )] {
        [
            (.normal, generateFlags(), .normal, .normal),
            (.one, generateFlags(phaseOne: true), .normal, .normal),
            (.two, generateFlags(phaseOne: true, phaseTwo: true), .normal, .normal),
            (.three, generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true), .normal, .normal),
            (.staticScreens, productionFlags(), .staticScreens, .staticScreensWithReader),
            (
                .four,
                generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true),
                .simplified,
                .simplified
            ),
            (
                .newUsers,
                generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: true),
                .simplified,
                .simplified
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

    private func makeStore(flags: [WordPressKit.FeatureFlag]) -> RemoteFeatureFlagStore {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        store.update(using: MockFeatureFlagRemote(flags: flags), waitOn: self)
        return store
    }

    private func appUIType(
        store: RemoteFeatureFlagStore,
        app: AppBrand = .wordpress,
        isReaderInWordPressAppEnabled: Bool
    ) -> RootViewCoordinator.AppUIType {
        RootViewCoordinator.appUIType(
            featureFlagStore: store,
            app: app,
            isReaderInWordPressAppEnabled: isReaderInWordPressAppEnabled
        )
    }

    private func generateFlags(phaseOne: Bool = false,
                               phaseTwo: Bool = false,
                               phaseThree: Bool = false,
                               phaseFour: Bool = false,
                               phaseStaticScreens: Bool = false,
                               phaseNewUsers: Bool = false,
                               phaseSelfHosted: Bool = false) -> [WordPressKit.FeatureFlag] {
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
