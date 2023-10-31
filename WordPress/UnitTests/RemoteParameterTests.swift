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

    init(config: [String: Any] = [:]) {
        self.config = config
        super.init()
    }

    override func getRemoteConfig(callback: @escaping RemoteConfigRemote.RemoteConfigResponseCallback) {
        callback(.success(config))
    }
}
