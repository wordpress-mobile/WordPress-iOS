import WordPressFlux
import XCTest

@testable import WordPress

final class AppUpdateCoordinatorTests: XCTestCase {

    private let service = MockAppStoreSearchService()
    private let presenter = MockAppUpdatePresenter()
    private let remoteConfigStore = RemoteConfigStoreMock()
    private var store: InMemoryUserDefaults!

    override func setUp() {
        store = InMemoryUserDefaults()
        service.didLookup = false
        presenter.didShowNotice = false
        presenter.didShowBlockingUpdate = false
        presenter.didOpenAppStore = false
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

    func testNotEnoughDaysHaveElapsedSinceCurrentVersionHasBeenReleased() async {
        // Given
        let coordinator = AppUpdateCoordinator(
            currentVersion: "24.6",
            currentOsVersion: "17.0",
            service: service,
            presenter: presenter,
            remoteConfigStore: remoteConfigStore,
            store: store,
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
        service.didLookup = false
        presenter.didShowNotice = false

        // When we check for updates again
        await coordinator.checkForAppUpdates()

        // Then the service doesn't fetch the app store info, and the
        // presenter doesn't show the flexible notice
        XCTAssertFalse(service.didLookup)
        XCTAssertFalse(presenter.didShowNotice)
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
            store: store,
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

    // MARK: - AppUpdatePresenter flexible notice guard

    func testShowNoticePostsExactlyOneFlexibleNotice() throws {
        // Given
        let dispatcher = ActionDispatcher()
        let noticeStore = NoticeStore(dispatcher: dispatcher)
        let presenter = AppUpdatePresenter(noticeStore: noticeStore, dispatcher: dispatcher)
        let appStoreInfo = try makeAppStoreInfo()

        // When
        presenter.showNotice(using: appStoreInfo)

        // Then
        XCTAssertEqual(noticeStore.currentNotice?.tag, AppUpdatePresenter.flexibleUpdateNoticeTag)
    }

    func testShowNoticeSuppressesSecondFlexibleNoticeWhileOneIsShowing() throws {
        // Given
        let dispatcher = ActionDispatcher()
        let noticeStore = NoticeStore(dispatcher: dispatcher)
        let presenter = AppUpdatePresenter(noticeStore: noticeStore, dispatcher: dispatcher)
        let appStoreInfo = try makeAppStoreInfo()
        presenter.showNotice(using: appStoreInfo)
        let firstNotice = try XCTUnwrap(noticeStore.currentNotice)

        // When a second presentation races in while the first is still showing
        presenter.showNotice(using: appStoreInfo)

        // Then the current notice is still the first one and nothing was queued
        XCTAssertEqual(noticeStore.currentNotice, firstNotice)
        // Dismissing the current notice leaves no queued duplicate behind
        ActionDispatcher.dispatch(NoticeAction.dismiss, dispatcher: dispatcher)
        XCTAssertNil(noticeStore.currentNotice)
    }

    func testShowNoticeCanPostAgainAfterPreviousNoticeIsCleared() throws {
        // Given
        let dispatcher = ActionDispatcher()
        let noticeStore = NoticeStore(dispatcher: dispatcher)
        let presenter = AppUpdatePresenter(noticeStore: noticeStore, dispatcher: dispatcher)
        let appStoreInfo = try makeAppStoreInfo()
        presenter.showNotice(using: appStoreInfo)
        XCTAssertNotNil(noticeStore.currentNotice)

        // When the first notice is cleared and a later legitimate cycle posts again
        ActionDispatcher.dispatch(NoticeAction.dismiss, dispatcher: dispatcher)
        XCTAssertNil(noticeStore.currentNotice)
        presenter.showNotice(using: appStoreInfo)

        // Then the guard does not permanently latch
        XCTAssertEqual(noticeStore.currentNotice?.tag, AppUpdatePresenter.flexibleUpdateNoticeTag)
    }

    private func makeAppStoreInfo() throws -> AppStoreLookupResponse.AppStoreInfo {
        let data = try Bundle.test.json(named: "app-store-lookup-response")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(AppStoreLookupResponse.self, from: data)
        return try XCTUnwrap(response.results.first)
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
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppStoreLookupResponse.self, from: data)
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
