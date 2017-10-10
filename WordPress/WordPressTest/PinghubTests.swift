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
        let message = loadJSONMessage(name: "notes-action-push")!
        let action = PinghubClient.Action.from(message: message)

        guard case .some(.push(let noteID, let userID, _, _)) = action else {
            XCTFail("Action is of the wrong type")
            return
        }
        XCTAssertEqual(noteID, 67890)
        XCTAssertEqual(userID, 12345)
    }

    func testActionDelete() {
        let message = loadJSONMessage(name: "notes-action-delete")!
        let action = PinghubClient.Action.from(message: message)

        guard case .some(.delete(let noteID)) = action else {
            XCTFail("Action is of the wrong type")
            return
        }
        XCTAssertEqual(noteID, 67890)
    }

    func testActionUnsupported() {
        let message = loadJSONMessage(name: "notes-action-unsupported")!
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
        let path = Bundle(for: PingHubTests.self).path(forResource: "notes-action-push", ofType: "json")!
        let text = try! String(contentsOfFile: path)
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onText?(text)

        guard case .some(.push(let noteID, let userID, _, _)) = delegate.receivedAction else {
            XCTFail("Didn't receive the right action")
            return
        }
        XCTAssertEqual(noteID, 67890)
        XCTAssertEqual(userID, 12345)
    }

    func testClientHandlesUnknownMessage() {
        let path = Bundle(for: PingHubTests.self).path(forResource: "notes-action-unsupported", ofType: "json")!
        let text = try! String(contentsOfFile: path)
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onText?(text)

        XCTAssertNil(delegate.receivedAction)
        XCTAssertNotNil(delegate.unexpected)
    }

    func testClientHandlesUnknownData() {
        var number = 1
        let data = Data(bytes: &number, count: MemoryLayout<Int>.size)
        let socket = MockSocket()
        let delegate = MockPingHubDelegate()
        let client = PinghubClient(socket: socket)
        client.delegate = delegate

        socket.onData?(data)

        XCTAssertNil(delegate.receivedAction)
        XCTAssertNotNil(delegate.unexpected)
    }
}

private extension PingHubTests {
    func loadJSONMessage(name: String) -> [String: AnyObject]? {
        return JSONLoader().loadFile(name, type: "json")
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
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    var onData: ((Data) -> Void)?
}

class MockPingHubDelegate: PinghubClientDelegate {
    var connected = false
    var receivedAction: PinghubClient.Action? = nil
    var unexpected: PinghubClient.Unexpected? = nil

    func pingubDidConnect(_ client: PinghubClient) {
        connected = true
    }

    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?) {
        connected = false
    }

    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action) {
        receivedAction = action
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        unexpected = message
    }
}
