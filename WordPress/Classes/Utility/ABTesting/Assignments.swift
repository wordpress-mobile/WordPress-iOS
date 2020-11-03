import Foundation

struct Assignments: Decodable {
    let ttl: Int
    let variations: [String: String?]
}
