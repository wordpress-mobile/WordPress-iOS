import Foundation

nonisolated struct Site: Codable, Equatable, Identifiable, Hashable, Sendable {
    let id: Int64
    let name: String
}

#if DEBUG
extension Site {
    static let previewSeed: [Site] = [
        Site(id: 1, name: "My Personal Blog"),
        Site(id: 2, name: "Travel Notes"),
        Site(id: 3, name: "Cooking Adventures"),
    ]
}
#endif
