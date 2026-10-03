import Foundation
import XCTest
import Starscream

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
        wait(for: [delegate.connected!], timeout: 2)
    }

    func testDisconnect() throws {
        let (_, client, delegate) = try connect()

        delegate.disconnected = expectation(description: "Disconnected to pinghub")
        client.disconnect()
        wait(for: [delegate.disconnected!], timeout: 2)
    }

    func testReceiveMessage() throws {
        let (server, client, delegate) = try connect()

        let exp = expectation(description: "Received expected note IDs")
        delegate.onActionReceived = {
            if delegate.noteIDs == [2] {
                exp.fulfill()
            }
        }

        server.broadcast(message: likePost)
        wait(for: [exp], timeout: 20)

        client.disconnect()
    }

    func testReceiveManyMessage() throws {
        let (server, client, delegate) = try connect()

        let exp = expectation(description: "Received all expected note IDs")
        delegate.onActionReceived = {
            if delegate.noteIDs == [2, 3, 4] {
                exp.fulfill()
            }
        }

        server.broadcast(message: likePost)
        server.broadcast(message: unlikePost)
        server.broadcast(message: commentOnPost)
        wait(for: [exp], timeout: 20)

        client.disconnect()
    }

    func testReceiveUnexpectedMessage() throws {
        let (server, client, delegate) = try connect()

        let exp = expectation(description: "Received unexpected message")
        delegate.onUnexpectedMessageReceived = {
            if delegate.unexpectedMessages.count == 1 {
                exp.fulfill()
            }
        }

        server.broadcast(message: #"{"foo": "bar"}"#)
        wait(for: [exp], timeout: 20)

        client.disconnect()
    }

    private func connect() throws -> (PinghubServer, PinghubClient, PinghubClientDelegateSpy) {
        let server = try XCTUnwrap(PinghubServer())
        let client = PinghubClient(token: "auth-token", endpoint: URL(string: "http://localhost:\(server.port)"))

        let delegate = PinghubClientDelegateSpy()
        client.delegate = delegate

        // Wait for both ends: the client can see the upgrade response before the server has
        // registered the connection, and a broadcast sent in between would reach nobody.
        delegate.connected = expectation(description: "Connected to pinghub")
        let registered = expectation(description: "Server registered the client")
        server.onClientConnected = { registered.fulfill() }
        client.connect()
        wait(for: [delegate.connected!, registered], timeout: 2)

        return (server, client, delegate)
    }
}

/// A websocket server to simulate sending push notifications from WP.com Pinghub endpoint.
private class PinghubServer {
    let server: WebSocketServer
    let port: UInt16

    var clients: [ServerConnection] = []
    var onClientConnected: (() -> Void)?

    init?() {
        // Let the OS pick the port. `WebSocketServer.start` returns before the listener binds, so
        // it can't report a port that's already taken (for example by a listener from an earlier
        // test, which Starscream offers no way to stop), and the client would connect to that
        // listener instead.
        guard let port = Self.unusedPort() else { return nil }

        let server = WebSocketServer()
        if let error = server.start(address: "localhost", port: port) {
            print("[Pinghub Server] failed to start at port \(port): \(error)")
            return nil
        }

        print("[Pinghub Server] started at port \(port)")

        self.server = server
        self.port = port

        server.onEvent = { [weak self] event in
            print("[Pinghub Server] received an event: \(event)")

            // Events arrive on the connection's queue; keep `clients` on the main thread, where
            // the tests read it.
            DispatchQueue.main.async {
                guard let self else { return }

                switch event {
                case let .connected(client, _):
                    self.clients.append(client as! ServerConnection)
                    self.onClientConnected?()
                case let .disconnected(client, _, _):
                    if let index = self.clients.firstIndex(where: { $0 === (client as! ServerConnection) }) {
                        self.clients.remove(at: index)
                    }
                default:
                    break
                }
            }
        }
    }

    /// Binds a socket to port 0 so the OS assigns a free port, then releases it for the server.
    private static func unusedPort() -> UInt16? {
        let fd = socket(AF_INET6, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }
        defer { close(fd) }

        // Accept IPv4 too, so the port is free on both stacks that "localhost" may resolve to.
        var v6Only: Int32 = 0
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &v6Only, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in6()
        address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        address.sin6_family = sa_family_t(AF_INET6)
        address.sin6_addr = in6addr_any
        address.sin6_port = 0

        var length = socklen_t(MemoryLayout<sockaddr_in6>.size)
        let succeeded = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, length) == 0 && getsockname(fd, $0, &length) == 0
            }
        }
        guard succeeded else { return nil }

        return UInt16(bigEndian: address.sin6_port)
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

    var onActionReceived: (() -> Void)?
    var onUnexpectedMessageReceived: (() -> Void)?

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
        onActionReceived?()
    }

    func pinghub(_ client: PinghubClient, unexpected message: PinghubClient.Unexpected) {
        unexpectedMessages.append(message)
        onUnexpectedMessageReceived?()
    }
}
