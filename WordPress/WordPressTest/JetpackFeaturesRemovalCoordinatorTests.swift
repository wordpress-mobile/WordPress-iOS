import XCTest
@testable import WordPress

final class JetpackFeaturesRemovalCoordinatorTests: CoreDataTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        contextManager.useAsSharedInstance(untilTestFinished: self)
        mockUserDefaults = InMemoryUserDefaults()
        let account = AccountBuilder(contextManager).build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
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

    func testSiteCreationPhaseTwo() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
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

    func testSiteCreationPhaseTwoPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: false, phaseSelfHosted: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote, waitOn: self)
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

    // MARK: Helpers

    private func generateFlags(phaseOne: Bool,
                               phaseTwo: Bool,
                               phaseThree: Bool,
                               phaseFour: Bool,
                               phaseNewUsers: Bool,
                               phaseSelfHosted: Bool) -> [WordPressKit.FeatureFlag] {
        return [
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseOne.remoteKey, value: phaseOne),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseTwo.remoteKey, value: phaseTwo),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseThree.remoteKey, value: phaseThree),
            .init(title: RemoteFeatureFlag.jetpackFeaturesRemovalPhaseFour.remoteKey, value: phaseFour),
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

private extension RemoteFeatureFlagStore {
    func update(using remote: FeatureFlagRemote, waitOn test: XCTestCase) {
        let exp = test.expectation(description: "Store finishes update")
        update(using: remote) {
            exp.fulfill()
        }
        test.wait(for: [exp], timeout: 1)
    }
}
