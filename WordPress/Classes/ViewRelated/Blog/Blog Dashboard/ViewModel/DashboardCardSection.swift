import Foundation

/// Represents a section in the Dashboard Collection View
class DashboardCardSection: Hashable {
    let id: String
    let subtype: String?

    init(id: String, subtype: String? = nil) {
        self.id = id
        self.subtype = subtype
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(subtype)
    }

    static func == (lhs: DashboardCardSection, rhs: DashboardCardSection) -> Bool {
        lhs.id == rhs.id && lhs.subtype == rhs.subtype
    }
}
