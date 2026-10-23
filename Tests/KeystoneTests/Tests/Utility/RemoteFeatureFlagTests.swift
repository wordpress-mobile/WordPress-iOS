import XCTest
@testable import WordPress

class RemoteFeatureFlagTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
    }

    func testThatDeviceIdIsTheSameForEveryInstanceOfTheStore() {
        // Disable the refresh rate limit: this test expects both updates to fetch.
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults, minimumRefreshInterval: 0)
        let mock = MockFeatureFlagRemote()
        var deviceId = ""

        let exp = expectation(description: "deviceIdCallback must be called twice")
        exp.expectedFulfillmentCount = 2

        mock.deviceIdCallback = {
            deviceId.isEmpty ? deviceId = $0 : XCTAssertEqual(deviceId, $0)
            exp.fulfill()
        }

        store.update(using: mock, waitOn: self)
        store.update(using: mock, waitOn: self)

        wait(for: [exp], timeout: 1.0)
    }

    func testThatStoreDoesNotHaveValueForColdCache() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyEnabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyDisabledFeature.remoteKey))
    }

    func testThatUpdateCachesNewFlags() {
        let mock = MockFeatureFlagRemote(mockFlags: MockFeatureFlag.remoteCases)
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        store.update(using: mock, waitOn: self)

        // All of the remotely defined values should be present
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature.remoteKey))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature.remoteKey))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature.remoteKey))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature.remoteKey))

        // All of the remotely undefined values should not be present
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyEnabledFeature.remoteKey))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyDisabledFeature.remoteKey))

        // The remotely enabled flags should return true
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature.remoteKey)!)
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature.remoteKey)!)

        // The remotely disabled flags should return false
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature.remoteKey)!)
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature.remoteKey)!)
    }

    // MARK: - Rate Limiting

    func testThatSecondUpdateWithinMinimumRefreshIntervalIsSkipped() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()

        let exp = expectation(description: "Both callbacks fire")
        exp.expectedFulfillmentCount = 2

        store.update(using: mock) { exp.fulfill() }
        store.update(using: mock) { exp.fulfill() }

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(mock.fetchCount, 1)
    }

    func testThatForcedUpdateBypassesMinimumRefreshInterval() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()

        let exp = expectation(description: "Both callbacks fire")
        exp.expectedFulfillmentCount = 2

        store.update(using: mock) { exp.fulfill() }
        store.update(using: mock, force: true) { exp.fulfill() }

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(mock.fetchCount, 2)
    }

    func testThatUpdateWithRecentFetchIsSkipped() {
        mockUserDefaults.set(Date(), forKey: RemoteFeatureFlagStore.Constants.LastFetchedDateKey)
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()

        store.update(using: mock, waitOn: self)

        XCTAssertEqual(mock.fetchCount, 0)
    }

    func testThatUpdateAfterMinimumRefreshIntervalFetchesAgain() {
        mockUserDefaults.set(Date().addingTimeInterval(-600), forKey: RemoteFeatureFlagStore.Constants.LastFetchedDateKey)
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()

        store.update(using: mock, waitOn: self)

        XCTAssertEqual(mock.fetchCount, 1)
    }

    func testThatFailedUpdateDoesNotSuppressRetry() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()
        mock.error = NSError(domain: "test", code: 0)

        store.update(using: mock, waitOn: self)
        // The failure must not stamp the last-fetched date, so the next
        // update retries instead of being rate limited.
        store.update(using: mock, waitOn: self)

        XCTAssertEqual(mock.fetchCount, 2)
    }
}

class MockFeatureFlagRemote: FeatureFlagRemote {

    var flags: FeatureFlagList
    var deviceIdCallback: ((String) -> Void)?
    var fetchCount = 0
    var error: Error?

    init(mockFlags: [MockFeatureFlag] = []) {
        self.flags = mockFlags
            .compactMap { $0.toFeatureFlag }
        super.init()
    }

    init(flags: [WordPressKit.FeatureFlag]) {
        self.flags = flags
        super.init()
    }

    public override func getRemoteFeatureFlags(forDeviceId deviceId: String, callback: @escaping FeatureFlagResponseCallback) {
        fetchCount += 1
        deviceIdCallback?(deviceId)
        if let error {
            callback(.failure(error))
        } else {
            callback(.success(flags))
        }
    }
}
