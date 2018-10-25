
/// Models a Site Vertical
struct SiteVertical {
    let id: Identifier
    let title: String
}

extension SiteVertical: Equatable {
    static func ==(lhs: SiteVertical, rhs: SiteVertical) -> Bool {
        return lhs.id == rhs.id
    }
}
