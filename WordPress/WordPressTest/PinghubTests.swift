import XCTest
@testable import WordPress

class PingHubTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testActionPush() {
        let message = loadJSONMessage("notes-action-push")!
        let action = PinghubClient.Action.from(message: message)

        guard case .Some(.push(let noteID, let userID, _, _)) = action else {
            XCTFail("Action is of the wrong type")
            return
        }
        XCTAssertEqual(noteID, 67890)
        XCTAssertEqual(userID, 12345)
    }

    func testActionDelete() {
        let message = loadJSONMessage("notes-action-delete")!
        let action = PinghubClient.Action.from(message: message)

        guard case .Some(.delete(let noteID)) = action else {
            XCTFail("Action is of the wrong type")
            return
        }
        XCTAssertEqual(noteID, 67890)
    }

    func testActionUnsupported() {
        let message = loadJSONMessage("notes-action-unsupported")!
        let action = PinghubClient.Action.from(message: message)
        XCTAssertNil(action)
    }

    func testClientConnectsAndDisconnects() {
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        client.connect()

        XCTAssertTrue(delegate.connected)

        client.disconnect()

        XCTAssertFalse(delegate.connected)
    }

    func testClientParseAction() {
        let path = NSBundle(forClass: PingHubTests.self).pathForResource("notes-action-push", ofType: "json")!
        let text = try! String(contentsOfFile: path)
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onText?(text)

        guard case .Some(.push(let noteID, let userID, _, _)) = delegate.receivedAction else {
            XCTFail("Didn't receive the right action")
            return
        }
        XCTAssertEqual(noteID, 67890)
        XCTAssertEqual(userID, 12345)
    }

    func testClientHandlesUnknownMessage() {
        let path = NSBundle(forClass: PingHubTests.self).pathForResource("notes-action-unsupported", ofType: "json")!
        let text = try! String(contentsOfFile: path)
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onText?(text)

        XCTAssertNil(delegate.receivedAction)
        XCTAssertNotNil(delegate.unexpectedMessage)
    }

    func testClientHandlesUnknownData() {
        var number = 1
        let data = NSData(bytes: &number, length: sizeof(number.dynamicType))
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onData?(data)

        XCTAssertNil(delegate.receivedAction)
        XCTAssertNotNil(delegate.unexpectedMessage)
    }
}

private extension PingHubTests {
    func loadJSONMessage(name: String) -> [String: AnyObject]? {
        guard let path = NSBundle(forClass: self.dynamicType).pathForResource(name, ofType: "json"),
            let data = NSData(contentsOfFile: path),
            let result = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
                return nil
        }

        return result
    }
}

class MockSocket: Socket {
    func connect() {
        onConnect?()
    }

    func disconnect() {
        onDisconnect?(nil)
    }

    var onConnect: (() -> Void)?
    var onDisconnect: ((NSError?) -> Void)?
    var onText: ((String) -> Void)?
    var onData: ((NSData) -> Void)?
}

class MockPingHubDelegate: PinghubClientDelegate {
    var connected = false
    var receivedAction: PinghubClient.Action? = nil
    var unexpectedMessage: String? = nil

    func pingubConnected(client client: PinghubClient) {
        connected = true
    }

    func pinghubDisconnected(client client: PinghubClient, error: ErrorType?) {
        connected = false
    }

    func pinghubActionReceived(client client: PinghubClient, action: PinghubClient.Action) {
        receivedAction = action
    }

    func pinghubUnexpectedDataReceived(client client: PinghubClient, message: String) {
        unexpectedMessage = message
    }
}
