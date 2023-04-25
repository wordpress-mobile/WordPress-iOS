import Foundation

/// Acts as a wrapper around decodable types, and marks them as failable.
/// This allows the decoding process to succeed even if the decoder was unable to decode a failable item.
struct FailableDecodable<T: Decodable & Hashable>: Decodable {
    let result: Result<T, Error>

    var value: T? {
        return try? result.get()
    }

    init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}

extension FailableDecodable: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    static func == (lhs: FailableDecodable<T>, rhs: FailableDecodable<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
