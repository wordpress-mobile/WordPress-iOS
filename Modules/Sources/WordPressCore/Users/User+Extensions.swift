import WordPressAPI
import WordPressAPIInternal // Required for `UserRole` Equatable conformance – it'd be nice to not need this.

public extension UserRole {
    var displayString: String {
        self.rawValue.capitalized
    }
}

extension UserRole: @retroactive Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string: String = try container.decode(String.self)
        self = .custom(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension UserRole: @retroactive Comparable {

    public static func < (lhs: UserRole, rhs: UserRole) -> Bool {
        let lhsIndex = Self.order.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = Self.order.firstIndex(of: rhs) ?? Int.max
        return lhsIndex < rhsIndex
    }

    private static let order: [UserRole] = [
        .superAdmin,
        .administrator,
        .editor,
        .author,
        .contributor,
        .subscriber
    ]
}
