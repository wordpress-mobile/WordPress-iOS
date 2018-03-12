import Foundation

struct SearchIdentifierGenerator {
    internal static let separator = "~~~"

    internal static func composeUniqueIdentifier(domain: String, identifier: String) -> String {
        return "\(domain)\(separator)\(identifier)"
    }

    internal static func decomposeFromUniqueIdentifier(_ combined: String) -> (domain: String, identifier: String) {
        let components = combined.components(separatedBy: separator)
        return (components[0], components[1])
    }
}
