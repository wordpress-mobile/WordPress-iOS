import XCTest
@testable import WordPress

final class JetpackFeaturesRemovalCoordinatorTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
    }

    // MARK: General Phase Tests

    func testNormalGeneralPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testNewUsersGeneralPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: true)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .newUsers)
    }

    func testNewUsersGeneralPhasePrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: true)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .newUsers)
    }

    func testGeneralPhaseOne() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)
    }

    func testGeneralPhaseTwo() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testGeneralPhaseTwoPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testGeneralPhaseThree() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: true, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .three)
    }

    func testGeneralPhaseThreePrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .three)
    }

    func testGeneralPhaseFour() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .four)
    }

    func testGeneralPhaseFourPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .four)
    }

    // MARK: Site Creation Phase Tests

    func testNormalSiteCreationPhase() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)

        // When
        let phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .normal)
    }

    func testSiteCreationPhaseOne() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: true, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: true, phaseThree: false, phaseFour: false, phaseNewUsers: false)
        remote.flags = flags
        store.update(using: remote)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: true, phaseFour: false, phaseNewUsers: false)
        remote.flags = flags
        store.update(using: remote)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .one)
    }

    func testSiteCreationPhaseTwo() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: true, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)

        // When
        flags = generateFlags(phaseOne: false, phaseTwo: false, phaseThree: false, phaseFour: false, phaseNewUsers: true)
        remote.flags = flags
        store.update(using: remote)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    func testSiteCreationPhaseTwoPrecedence() {
        // Given
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        // When
        var flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: true, phaseNewUsers: false)
        let remote = MockFeatureFlagRemote(flags: flags)
        store.update(using: remote)
        var phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)

        // When
        flags = generateFlags(phaseOne: true, phaseTwo: true, phaseThree: true, phaseFour: false, phaseNewUsers: true)
        remote.flags = flags
        store.update(using: remote)
        phase = JetpackFeaturesRemovalCoordinator.siteCreationPhase(featureFlagStore: store)

        // Then
        XCTAssertEqual(phase, .two)
    }

    // MARK: Helpers

    private func generateFlags(phaseOne: Bool,
                               phaseTwo: Bool,
                               phaseThree: Bool,
                               phaseFour: Bool,
                               phaseNewUsers: Bool) -> [WordPressKit.FeatureFlag] {
        return [
            .init(title: FeatureFlag.jetpackFeaturesRemovalPhaseOne.remoteKey ?? "", value: phaseOne),
            .init(title: FeatureFlag.jetpackFeaturesRemovalPhaseTwo.remoteKey ?? "", value: phaseTwo),
            .init(title: FeatureFlag.jetpackFeaturesRemovalPhaseThree.remoteKey ?? "", value: phaseThree),
            .init(title: FeatureFlag.jetpackFeaturesRemovalPhaseFour.remoteKey ?? "", value: phaseFour),
            .init(title: FeatureFlag.jetpackFeaturesRemovalPhaseNewUsers.remoteKey ?? "", value: phaseNewUsers),
        ]
    }
}
