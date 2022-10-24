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

        store.update(using: mock)
        store.update(using: mock)

        wait(for: [exp], timeout: 1.0)
    }

    func testThatStoreReturnsCorrectCompileTimeDefaultForColdCache() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature))
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature))
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyUndefinedLocallyEnabledFeature))
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature))
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature))
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyUndefinedLocallyDisabledFeature))
    }

    func testThatStoreDoesNotHaveValueForColdCache() {
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)
        let flag = FeatureFlag.allCases.first!
        XCTAssertFalse(store.hasValue(for: flag))
    }

    func testThatUpdateCachesNewFlags() {
        let mock = MockFeatureFlagRemote(mockFlags: MockFeatureFlag.remoteCases)
        let store = RemoteFeatureFlagStore(persistenceStore: mockUserDefaults)

        store.update(using: mock)

        // All of the remotely defined values should be present
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature))
        XCTAssertTrue(store.hasValue(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature))

        // All of the remotely undefined values should not be present
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyEnabledFeature))
        XCTAssertFalse(store.hasValue(for: MockFeatureFlag.remotelyUndefinedLocallyDisabledFeature))

        // The remotely enabled flags should return true
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyEnabledLocallyEnabledFeature))
        XCTAssertTrue(store.value(for: MockFeatureFlag.remotelyEnabledLocallyDisabledFeature))

        // The remotely disabled flags should return false
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyDisabledLocallyEnabledFeature))
        XCTAssertFalse(store.value(for: MockFeatureFlag.remotelyDisabledLocallyDisabledFeature))
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
