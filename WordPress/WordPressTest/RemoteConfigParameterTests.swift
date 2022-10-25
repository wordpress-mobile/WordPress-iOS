import XCTest
@testable import WordPress

final class RemoteConfigParameterTests: XCTestCase {

    private var remoteConfigStore: RemoteConfigStore!

    override func setUp() {
        let mockUserDefaults = InMemoryUserDefaults()
        let config = ["param_key": "server_value"]
        let mock = MockRemoteConfigRemote(config: config)
        remoteConfigStore = RemoteConfigStore(remote: mock, persistenceStore: mockUserDefaults)
    }

    func testReturningServerValueIfPresent() {
        // Given
        let param = RemoteConfigParameter(key: "param_key", defaultValue: "default_value", store: remoteConfigStore)
        remoteConfigStore.update()

        // When
        let value = param.value

        // Then
        XCTAssertEqual(value, "server_value")
    }

    func testFallingBackToDefaultValue() {
        // Given
        let param = RemoteConfigParameter(key: "param_key", defaultValue: "default_value", store: remoteConfigStore)

        // When
        let value = param.value

        // Then
        XCTAssertEqual(value, "default_value")
    }

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
