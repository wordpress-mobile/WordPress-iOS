extension UserSuggestion: Comparable {
    public static func < (lus: UserSuggestion, rus: UserSuggestion) -> Bool {
        guard let ldn = lus.displayName,
              let rdn = rus.displayName else { return false }
        return ldn.localizedCaseInsensitiveCompare(rdn) == .orderedAscending
    }
}
