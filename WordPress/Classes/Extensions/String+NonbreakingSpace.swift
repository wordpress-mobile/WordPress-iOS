import Foundation

extension String {
    var replacingLastSpaceWithNonBreakingSpace: String {
        if let lastSpace = range(of: " ", options: .backwards, locale: .current) {
            return replacingCharacters(in: lastSpace, with: "\u{00a0}")
        }
        return self
    }
}
