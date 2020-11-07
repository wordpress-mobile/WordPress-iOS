import Foundation

/// Model that contains experiments variations and TTL
///
struct Assignments: Decodable {
    /// Time in seconds until the `variations` should be considered stale.
    let ttl: Int

    /// Mapping from experiment name to variation name.
    let variations: [String: String?]
}
