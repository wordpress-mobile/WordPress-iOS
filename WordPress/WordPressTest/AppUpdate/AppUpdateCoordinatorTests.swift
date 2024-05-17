import XCTest

@testable import WordPress

final class AppUpdateCoordinatorTests: XCTestCase {

    private let service = MockAppStoreSearchService()
    private let presenter = MockAppUpdatePresenter()
    private let remoteConfigStore = RemoteConfigStoreMock()

    func testInAppUpdatesDisabled() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
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

    func testFlexibleUpdateAvailableButOsVersionTooLow() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "14.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
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

    func testFlexibleUpdateAvailable() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            isJetpack: true,
            isLoggedIn: true,
            isInAppUpdatesEnabled: true
        )

        // When
        await coordinator.checkForAppUpdates()

        // Then
        XCTAssertTrue(service.didLookup)
        XCTAssertTrue(presenter.didShowNotice)
        XCTAssertFalse(presenter.didShowBlockingUpdate)
    }

    func testBlockingUpdateAvailable() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
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
    var didLookup = false

    var appID: String { "1234567890" }

    func lookup() async throws -> AppStoreLookupResponse {
        didLookup = true
        return try getMockLookupResponse()
    }

    private func getMockLookupResponse() throws -> AppStoreLookupResponse {
        let data = try Bundle.test.json(named: "app-store-lookup-response")
        return try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
    }
}

private final class MockAppUpdatePresenter: AppUpdatePresenterProtocol {
    var didShowNotice = false
    var didShowBlockingUpdate = false
    var didOpenAppStore = false

    func showNotice(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo) {
        didShowNotice = true
    }

    func showBlockingUpdate(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo) {
        didShowBlockingUpdate = true
    }

    func openAppStore(appStoreUrl: String) {
        didOpenAppStore = true
    }
}
