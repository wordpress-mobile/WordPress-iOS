extension UserSuggestion: Comparable {
    public static func < (lhs: UserSuggestion, rhs: UserSuggestion) -> Bool {
        guard let leftDisplayName = lhs.displayName,
              let rightDisplayName = rhs.displayName else { return false }
        return leftDisplayName.localizedCaseInsensitiveCompare(rightDisplayName) == .orderedAscending
    }
}
