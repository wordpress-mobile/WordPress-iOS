import Foundation
import Network

/// Length-prefixed message framing over a raw TCP `NWConnection`: a big-endian `UInt32` byte count
/// followed by that many bytes. The transfer is entirely app-to-app, so this replaces HTTP. A single
/// transfer is a short sequence of framed messages on one connection — sender: `intent`, then (after
/// the user scans the receiver's QR) the sealed envelope; receiver: a small JSON status — each read
/// one at a time with `readMessage`.
enum DebugSessionTransferFraming {
    /// Envelopes are a few hundred bytes; cap well above that to reject a bogus/hostile length.
    static let maxMessageBytes = 64 * 1024

    enum FramingError: Error {
        case invalidLength
        case connectionClosed
    }

    static func encode(_ payload: Data) -> Data {
        let count = UInt32(payload.count)
        var frame = Data([
            UInt8((count >> 24) & 0xFF),
            UInt8((count >> 16) & 0xFF),
            UInt8((count >> 8) & 0xFF),
            UInt8(count & 0xFF)
        ])
        frame.append(payload)
        return frame
    }

    /// Reads a single framed message: the 4-byte length prefix, then that many bytes.
    static func readMessage(from connection: NWConnection, completion: @escaping (Result<Data, Error>) -> Void) {
        readExactly(4, from: connection) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let header):
                let length = header.reduce(0) { ($0 << 8) | Int($1) }
                guard length > 0, length <= maxMessageBytes else {
                    completion(.failure(FramingError.invalidLength))
                    return
                }
                readExactly(length, from: connection, completion: completion)
            }
        }
    }

    private static func readExactly(
        _ count: Int,
        from connection: NWConnection,
        buffer: Data = Data(),
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: count - buffer.count) {
            data,
            _,
            isComplete,
            error in
            if let error {
                completion(.failure(error))
                return
            }
            var buffer = buffer
            if let data {
                buffer.append(data)
            }
            if buffer.count >= count {
                completion(.success(buffer.prefix(count)))
            } else if isComplete {
                completion(.failure(FramingError.connectionClosed))
            } else {
                readExactly(count, from: connection, buffer: buffer, completion: completion)
            }
        }
    }
}
