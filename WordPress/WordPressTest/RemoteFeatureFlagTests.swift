import XCTest
@testable import WordPress

class RemoteFeatureFlagTests: XCTestCase {

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
    }

    func testThatDeviceIdIsTheSameForEveryInstanceOfTheStore() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let mock = MockFeatureFlagRemote()
        var deviceId = ""

        let exp = expectation(description: "deviceIdCallback must be called twice")
        exp.expectedFulfillmentCount = 2

        mock.deviceIdCallback = {
            deviceId == "" ? deviceId = $0 : XCTAssertEqual(deviceId, $0)
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
}

class MockFeatureFlagRemote: FeatureFlagRemote {

    var flags: FeatureFlagList
    var deviceIdCallback: ((String) -> Void)?

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
        deviceIdCallback?(deviceId)
        callback(.success(flags))
    }
}
