import Foundation
import Network

/// Sends a sealed WordPress.com session to a receiver on the local network.
///
/// This is the token-holder side of the transfer: a physical device pushes its (already encrypted)
/// session to a receiver — most usefully one running in the iOS Simulator, reachable via the host
/// Mac's LAN address. Debug/internal builds only.
enum DebugSessionTransferSender {
    enum SendError: Error, LocalizedError {
        case invalidHost
        case notLocalHost
        case invalidResponse
        case timedOut
        case rejected(String)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case .invalidHost:
                return NSLocalizedString(
                    "debugMenu.sessionTransfer.send.error.invalidHost",
                    value: "Invalid address.",
                    comment: "Error shown when the session transfer destination address is malformed"
                )
            case .notLocalHost:
                return NSLocalizedString(
                    "debugMenu.sessionTransfer.send.error.notLocalHost",
                    value: "Sessions can only be sent to a device on your local network.",
                    comment: "Error shown when refusing to send a session to a non-local address"
                )
            case .invalidResponse:
                return NSLocalizedString(
                    "debugMenu.sessionTransfer.send.error.invalidResponse",
                    value: "Unexpected response from the other device.",
                    comment: "Error shown when the receiver's response could not be understood"
                )
            case .timedOut:
                return NSLocalizedString(
                    "debugMenu.sessionTransfer.send.error.timedOut",
                    value: "Timed out reaching the other device.",
                    comment: "Error shown when the receiver could not be reached in time"
                )
            case .rejected(let reason):
                return reason
            case .transport(let reason):
                return reason
            }
        }
    }

    /// Sends the sealed envelope to a receiver at `host:port` (the deep-link path). Guards that the
    /// destination is local so a crafted link can't exfiltrate the token to a public host.
    static func send(_ envelope: DebugSessionEnvelope, toHost host: String, port: UInt16) async throws {
        guard isLocalHost(host) else { throw SendError.notLocalHost }
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { throw SendError.invalidHost }
        try await send(envelope, to: .hostPort(host: NWEndpoint.Host(host), port: nwPort))
    }

    /// Opens a raw TCP connection to `endpoint` — a Bonjour service (from the browser) or a host and
    /// port (from the deep link) — sends the sealed envelope as one length-prefixed message, and
    /// awaits the receiver's status reply.
    ///
    /// Plain TCP over `NWConnection`: the envelope is already encrypted to the receiver's public
    /// key, so there's nothing for a sniffer to read, and Network.framework isn't subject to ATS.
    /// The first connection to a local address surfaces the iOS Local Network permission prompt.
    static func send(_ envelope: DebugSessionEnvelope, to endpoint: NWEndpoint) async throws {
        let requestFrame = DebugSessionTransferFraming.encode(try JSONEncoder().encode(envelope))
        let connection = NWConnection(to: endpoint, using: .tcp)
        let queue = DispatchQueue(label: "org.wordpress.debug-session-transfer.sender")

        let responseData: Data = try await withCheckedThrowingContinuation { continuation in
            let once = ResumeOnce(continuation)

            // Cover the whole exchange, including time for the user to grant Local Network access.
            queue.asyncAfter(deadline: .now() + 20) {
                once.resume(throwing: SendError.timedOut)
                connection.cancel()
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(
                        content: requestFrame,
                        completion: .contentProcessed { error in
                            if let error {
                                once.resume(throwing: SendError.transport(error.localizedDescription))
                                connection.cancel()
                                return
                            }
                            DebugSessionTransferFraming.readMessage(from: connection) { result in
                                once.resume(with: result.mapError { SendError.transport($0.localizedDescription) })
                                connection.cancel()
                            }
                        }
                    )
                case .failed(let error):
                    once.resume(throwing: SendError.transport(error.localizedDescription))
                    connection.cancel()
                default:
                    // `.waiting` can occur while the Local Network prompt is up; wait for `.ready`
                    // or the timeout rather than failing.
                    break
                }
            }
            connection.start(queue: queue)
        }

        let response = try? JSONDecoder().decode([String: String].self, from: responseData)
        if let error = response?["error"] {
            throw SendError.rejected(error)
        }
        guard response?["status"] == "signed_in" else {
            throw SendError.invalidResponse
        }
    }

    /// Whether `host` is an IPv4 address on the local network (private, loopback, or link-local),
    /// or a `.local`/`localhost` name. Guards against a crafted deep link exfiltrating the token to
    /// a public server.
    static func isLocalHost(_ host: String) -> Bool {
        if host == "localhost" || host.hasSuffix(".local") { return true }
        let octets = host.split(separator: ".", omittingEmptySubsequences: false).compactMap { UInt8($0) }
        guard octets.count == 4 else { return false }
        switch (octets[0], octets[1]) {
        case (10, _), (127, _), (192, 168):
            return true
        case (169, 254), (172, 16...31):
            return true
        default:
            return false
        }
    }
}

/// Guarantees a `CheckedContinuation` is resumed exactly once across the connection's callbacks.
private final class ResumeOnce<T> {
    private var continuation: CheckedContinuation<T, Error>?
    private let lock = NSLock()

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<T, Error>) {
        lock.lock()
        defer { lock.unlock() }
        continuation?.resume(with: result)
        continuation = nil
    }

    func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
}
