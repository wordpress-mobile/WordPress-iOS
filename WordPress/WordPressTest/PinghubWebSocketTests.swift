import Foundation
import XCTest
import Starscream
import Nimble

@testable import WordPress

class PinghubWebSocketTests: XCTestCase {

    let likePost = #"{"user_id":1,"note_id":2,"newest_note_type":"like","newest_note_time":1707869897,"action":"push"}"#
    let unlikePost = #"{"action":"delete","note_id":3}"#
    let commentOnPost = #"{"user_id":1,"note_id":4,"newest_note_type":"comment","newest_note_time":1707869951,"action":"push"}"#

    func testConnect() throws {
        let server = try XCTUnwrap(PinghubServer())
        let client = PinghubClient(token: "auth-token", endpoint: URL(string: "http://localhost:\(server.port)"))

        let delegate = PinghubClientDelegateSpy()
        client.delegate = delegate

        delegate.connected = expectation(description: "Connected to pinghub")
        client.connect()
        wait(for: [delegate.connected!], timeout: 0.1)
    }

    func testDisconnect() throws {
        let (_, client, delegate) = try connect()

        delegate.disconnected = expectation(description: "Disconnected to pinghub")
        client.disconnect()
        wait(for: [delegate.disconnected!], timeout: 0.1)
    }

    func testReceiveMessage() throws {
        let (server, client, delegate) = try connect()

        server.broadcast(message: likePost)
        expect(delegate.noteIDs).toEventually(equal([2]))

        client.disconnect()
    }

    func testReceiveManyMessage() throws {
        let (server, client, delegate) = try connect()

        server.broadcast(message: likePost)
        server.broadcast(message: unlikePost)
        server.broadcast(message: commentOnPost)
        expect(delegate.noteIDs).toEventually(equal([2, 3, 4]))

        client.disconnect()
    }

    func testReceiveUnexpectedMessage() throws {
        let (server, client, delegate) = try connect()

        server.broadcast(message: #"{"foo": "bar"}"#)
        expect(delegate.unexpectedMessages.count).toEventually(equal(1))

        client.disconnect()
    }

    private func connect() throws -> (PinghubServer, PinghubClient, PinghubClientDelegateSpy) {
        let server = try XCTUnwrap(PinghubServer())
        let client = PinghubClient(token: "auth-token", endpoint: URL(string: "http://localhost:\(server.port)"))

        let delegate = PinghubClientDelegateSpy()
        client.delegate = delegate

        delegate.connected = expectation(description: "Connected to pinghub")
        client.connect()
        wait(for: [delegate.connected!], timeout: 0.1)

        return (server, client, delegate)
    }

}

/// A websocket server to simulate sending push notifications from WP.com Pinghub endpoint.
private class PinghubServer {
    let server: WebSocketServer
    let port: UInt16

    var clients: [ServerConnection] = []

    init?() {
        var server: WebSocketServer?
        var port: UInt16 = 0

        var attempt = 5
        while server == nil && attempt > 0 {
            attempt -= 1

            server = WebSocketServer()
            port = (9000...9999).randomElement()!
            if server!.start(address: "localhost", port: port) == nil {
                break
            }
        }

        guard let server else { return nil }

        print("[Pinghub Server] started at port \(port)")

        self.server = server
        self.port = port

        server.onEvent = { [weak self] event in
            print("[Pinghub Server] received an event: \(event)")

            guard let self else { return }

            switch event {
            case let .connected(client, _):
                self.clients.append(client as! ServerConnection)
            case let .disconnected(client, _, _):
                if let index = self.clients.firstIndex(where: { $0 === (client as! ServerConnection) }) {
                    self.clients.remove(at: index)
                }
                break
            default:
                break
            }
        }
    }

    func broadcast(message: String) {
        for client in clients {
            client.write(data: message.data(using: .utf8)!, opcode: .textFrame)
        }
    }
}

private class PinghubClientDelegateSpy: PinghubClientDelegate {

    var connected: XCTestExpectation?
    var disconnected: XCTestExpectation?

    var actions: [PinghubClient.Action] = []
    var unexpectedMessages: [PinghubClient.Unexpected] = []

    var noteIDs: [Int] {
        actions.map {
            switch $0 {
            case let .push(noteID, _, _, _):
                return noteID
            case let .delete(noteID):
                return noteID
            }
        }
    }

    func pingubDidConnect(_ client: PinghubClient) {
        connected?.fulfill()
    }

    func pinghubDidDisconnect(_ client: PinghubClient, error: Error?) {
        disconnected?.fulfill()
    }

    func pinghub(_ client: PinghubClient, actionReceived action: PinghubClient.Action) {
        actions.append(action)
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        unexpectedMessages.append(message)
    }

}
