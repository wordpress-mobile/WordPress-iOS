import WordPressAPI
import WordPressAPIInternal // Required for `UserRole` Equatable conformance – it'd be nice to not need this.

public extension UserRole {
    var displayString: String {
        self.rawValue.capitalized
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
