import Foundation

struct SearchIdentifierGenerator {
    internal static let separator = "|~~~|"

    internal static func composeUniqueIdentifier(itemType: SearchItemType, domain: String, identifier: String) -> String {
        return "\(itemType.stringValue())\(separator)\(domain)\(separator)\(identifier)"
    }

    internal static func decomposeFromUniqueIdentifier(_ combined: String) -> (itemType: SearchItemType, domain: String, identifier: String) {
        let components = combined.components(separatedBy: separator)

        return (SearchItemType(index: components[0]), components[1], components[2])
    }
}
