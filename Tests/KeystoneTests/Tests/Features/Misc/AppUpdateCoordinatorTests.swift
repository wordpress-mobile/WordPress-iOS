@testable import WordPress
import XCTest

final class AppUpdateCoordinatorTests: XCTestCase {
    private let service = MockAppStoreSearchService()
    private let presenter = MockAppUpdatePresenter()
    private let remoteConfigStore = RemoteConfigStoreMock()
    private var checkThrottle: AppUpdateCheckThrottle!
    private var currentDateProvider: MockCurrentDateProvider!
    private var store: InMemoryUserDefaults!

    override func setUp() {
        store = InMemoryUserDefaults()
        checkThrottle = AppUpdateCheckThrottle()
        currentDateProvider = MockCurrentDateProvider()
        currentDateProvider.dateToReturn = Date(timeIntervalSince1970: 1_000_000)
        service.lookupCount = 0
        presenter.didShowNotice = false
        presenter.didShowBlockingUpdate = false
        presenter.didOpenAppStore = false
        presenter.showNoticeCount = 0
        super.setUp()
    }

    func testInAppUpdatesDisabled() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isLoggedIn: true,
            isInAppUpdatesEnabled: false
        )

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testNotLoggedIn() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isLoggedIn: false,
            isInAppUpdatesEnabled: true
        )

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testNotEnoughDaysHaveElapsedSinceCurrentVersionHasBeenReleased() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isLoggedIn: false,
            isInAppUpdatesEnabled: true,
            delayInDays: Int.max
        )

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testFlexibleUpdateAvailableButOsVersionTooLow() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "14.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertTrue(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testBlockingUpdateAvailableButOsVersionTooLow() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "14.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )
        remoteConfigStore.jetpackInAppUpdateBlockingVersion = "24.7"

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertTrue(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testFlexibleUpdateAvailableShownOnce() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )
        remoteConfigStore.inAppUpdateFlexibleIntervalInDays = 90

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertTrue(service.didLookup)
        XCTAssertTrue(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)

        // Reset service and presenter
        service.lookupCount = 0
        presenter.didShowNotice = false

        // When we check for updates again
        await coordinator.checkForAppUpdates()

        // Then the service doesn't fetch the app store info, and the
        // presenter doesn't show the flexible notice
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testImmediateDuplicateChecksAreThrottledBeforeFetching() async {
        // Given
        remoteConfigStore.inAppUpdateFlexibleIntervalInDays = 90
        let firstCoordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: InMemoryUserDefaults(),
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )
        let secondCoordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: InMemoryUserDefaults(),
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )

        // When
        await firstCoordinator.checkForAppUpdates()
        service.lookupCount = 0
        presenter.didShowNotice = false
        await secondCoordinator.checkForAppUpdates()

        // Then
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertEqual(presenter.showNoticeCount, 1)
    }

    func testDuplicateCheckThrottleAllowsLaterChecks() async {
        // Given
        remoteConfigStore.inAppUpdateFlexibleIntervalInDays = 90
        let firstCoordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: InMemoryUserDefaults(),
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )
        let secondCoordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: InMemoryUserDefaults(),
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )

        // When
        await firstCoordinator.checkForAppUpdates()
        currentDateProvider.dateToReturn = currentDateProvider.date().addingTimeInterval(5 * 60)
        await secondCoordinator.checkForAppUpdates()

        // Then
        XCTAssertEqual(service.lookupCount, 2)
        XCTAssertEqual(presenter.showNoticeCount, 2)
    }

    func testBlockingUpdateAvailable() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
            checkThrottle: checkThrottle,
            currentDateProvider: currentDateProvider,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )
        remoteConfigStore.jetpackInAppUpdateBlockingVersion = "24.7"

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertTrue(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
        XCTAssertTrue(presenter.didShowBlockingUpdate)
    }
}

private final class MockAppStoreSearchService: AppStoreSearchProtocol {
    var lookupCount = 0

    var didLookup: Bool {
        lookupCount > 0
    }

    var appID: String {
        "1234567890"
    }

    func lookup() async throws -> AppStoreLookupResponse {
        lookupCount += 1
        return try getMockLookupResponse()
    }

    private func getMockLookupResponse() throws -> AppStoreLookupResponse {
        let data = try Bundle.test.json(named: "app-store-lookup-response")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppStoreLookupResponse.self, from: data)
    }
}

private final class MockAppUpdatePresenter: AppUpdatePresenterProtocol {
    var didShowNotice = false
    var didShowBlockingUpdate = false
    var didOpenAppStore = false
    var showNoticeCount = 0

    func showNotice(using _: AppStoreLookupResponse.AppStoreInfo) {
        showNoticeCount += 1
        didShowNotice = true
    }

    func showBlockingUpdate(using _: AppStoreLookupResponse.AppStoreInfo) {
        didShowBlockingUpdate = true
    }

    func openAppStore(appStoreUrl _: String) {
        didOpenAppStore = true
    }
}
