extension UserSuggestion: Comparable {
    public static func < (lhs: UserSuggestion, rhs: UserSuggestion) -> Bool {
        if let leftDisplayName = lhs.displayName, let rightDisplayName = rhs.displayName {
            return leftDisplayName.localizedCaseInsensitiveCompare(rightDisplayName) == .orderedAscending
        } else if let leftUsername = lhs.username, let rightUsername = rhs.username {
            return leftUsername < rightUsername
        }

        return false
    }
}
