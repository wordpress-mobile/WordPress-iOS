import Foundation

public struct SearchIdentifierGenerator {
    internal static let separator = "|~~~|"

    internal static func composeUniqueIdentifier(
        itemType: SearchItemType,
        domain: String,
        identifier: String
    ) -> String {
        "\(itemType.stringValue())\(separator)\(domain)\(separator)\(identifier)"
    }

    /// Returns `nil` for identifiers that are not in the composite format or
    /// name an unknown item type. Identifiers arrive from the system (Spotlight
    /// activities), so the format cannot be assumed.
    public static func decomposeFromUniqueIdentifier(
        _ combined: String
    ) -> (itemType: SearchItemType, domain: String, identifier: String)? {
        let components = combined.components(separatedBy: separator)
        guard components.count == 3 else {
            return nil
        }
        let itemType = SearchItemType(index: components[0])
        guard itemType != .none else {
            return nil
        }
        return (itemType, components[1], components[2])
    }
}
