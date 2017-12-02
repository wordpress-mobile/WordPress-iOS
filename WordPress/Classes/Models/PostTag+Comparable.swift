
extension PostTag: Comparable {
    public static func <(lhs: PostTag, rhs: PostTag) -> Bool {
        guard let lhsName = lhs.name, let rhsName = rhs.name else {
            return false
        }

        return lhsName < rhsName
    }
}
