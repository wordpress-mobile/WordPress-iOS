
/// A site type. There is already a SiteType enum in the codebase. To be renamed after we get rid of the old code
struct SiteType {
    let id: Identifier
    let title: String
    let subtitle: String
    let icon: URL
}

extension SiteType: Equatable {
    static func ==(lhs: SiteType, rhs: SiteType) -> Bool {
        return lhs.id == rhs.id
    }
}
