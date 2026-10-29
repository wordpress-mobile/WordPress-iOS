import XCTest
@testable import WordPress

final class RemoteParameterTests: XCTestCase {

    private var remoteConfigStore: RemoteConfigStore!
    private var overrideStore: RemoteConfigOverrideStore!

    override func setUp() {
        let mockUserDefaults = InMemoryUserDefaults()
        let config = ["param_key": "server_value"]
        let mock = MockRemoteConfigRemote(config: config)
        remoteConfigStore = RemoteConfigStore(remote: mock, persistenceStore: mockUserDefaults)
        overrideStore = RemoteConfigOverrideStore(store: mockUserDefaults)
    }

    func testReturningServerValueIfPresent() {
        // Given
        let param = MockRemoteParameter(key: "param_key", defaultValue: "default_value")
        remoteConfigStore.update()

        // When
        let value: String? = param.value(using: remoteConfigStore, overrideStore: overrideStore)

        // Then
        XCTAssertEqual(value, "server_value")
    }

    func testFallingBackToDefaultValue() {
        // Given
        let param = MockRemoteParameter(key: "param_key", defaultValue: "default_value")

        // When
        let value: String? = param.value(using: remoteConfigStore, overrideStore: overrideStore)

        // Then
        XCTAssertEqual(value, "default_value")
    }

    func testReturningOverriddenValueIfPresent() {
        // Given
        let param = MockRemoteParameter(key: "param_key", defaultValue: "default_value")
        overrideStore.override(param, withValue: "overridden_value")
        remoteConfigStore.update()

        // When
        let value: String? = param.value(using: remoteConfigStore, overrideStore: overrideStore)

        // Then
        XCTAssertEqual(value, "overridden_value")
    }
}

struct MockRemoteParameter: RemoteParameter {
    let key: String
    let defaultValue: LosslessStringConvertible?
    let description = "description"
}

class MockRemoteConfigRemote: RemoteConfigRemote {

    var config: RemoteConfigDictionary
    var fetchCount = 0
    var error: Error?

    init(config: [String: Any] = [:]) {
        self.config = config
        super.init()
    }

    override func getRemoteConfig(callback: @escaping RemoteConfigRemote.RemoteConfigResponseCallback) {
        fetchCount += 1
        if let error {
            callback(.failure(error))
        } else {
            callback(.success(config))
        }
    }
}

final class RemoteConfigStoreRateLimitTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!
    private var mock: MockRemoteConfigRemote!
    private var store: RemoteConfigStore!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
        mock = MockRemoteConfigRemote(config: ["param_key": "server_value"])
        store = RemoteConfigStore(remote: mock, persistenceStore: mockUserDefaults)
    }

    func testThatSecondUpdateWithinMinimumRefreshIntervalIsSkipped() {
        store.update()
        store.update()

        XCTAssertEqual(mock.fetchCount, 1)
        XCTAssertEqual(store.value(for: "param_key") as? String, "server_value")
    }

    func testThatForcedUpdateBypassesMinimumRefreshInterval() {
        store.update()
        store.update(force: true)

        XCTAssertEqual(mock.fetchCount, 2)
    }

    func testThatUpdateWithRecentFetchIsSkipped() {
        mockUserDefaults.set(Date(), forKey: RemoteConfigStore.Constants.LastFetchedDateKey)

        store.update()

        XCTAssertEqual(mock.fetchCount, 0)
    }

    func testThatUpdateAfterMinimumRefreshIntervalFetchesAgain() {
        mockUserDefaults.set(Date().addingTimeInterval(-600), forKey: RemoteConfigStore.Constants.LastFetchedDateKey)

        store.update()

        XCTAssertEqual(mock.fetchCount, 1)
    }

    func testThatFailedUpdateDoesNotSuppressRetry() {
        mock.error = NSError(domain: "test", code: 0)

        store.update()
        // The failure must not stamp the last-fetched date, so the next
        // update retries instead of being rate limited.
        store.update()

        XCTAssertEqual(mock.fetchCount, 2)
    }
}
