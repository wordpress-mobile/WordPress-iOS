import Foundation
import Network

/// Sends a sealed WordPress.com session to a receiver on the local network.
///
/// This is the token-holder side of the transfer: a physical device pushes its (already encrypted)
/// session to a receiver — most usefully one running in the iOS Simulator, reachable via the host
/// Mac's LAN address. Debug/internal builds only.
enum DebugSessionTransferSender {
    enum SendError: Error, LocalizedError {
        case invalidResponse
        case timedOut
        case rejected(String)
        case transport(String)

        var errorDescription: String? {
            switch self {
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

    /// Opens a raw TCP connection to the receiver's Bonjour `endpoint` (from the browser), sends the
    /// sealed envelope as one length-prefixed message, and awaits the receiver's status reply.
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
