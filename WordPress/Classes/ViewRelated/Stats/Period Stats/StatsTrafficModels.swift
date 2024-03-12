import Foundation

struct StatsTrafficSection: Hashable {
    let periodType: PeriodType

    init(periodType: PeriodType) {
        self.periodType = periodType
    }
}

protocol HashableImmutableRow: ImmuTableRow, Hashable {}

extension HashableImmutableRow {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: type(of: self)))
    }
}

protocol StatsHashableImmuTableRow: HashableImmutableRow {
    var statSection: StatSection? { get }
}

extension StatsHashableImmuTableRow {
    /// The diffable data source relies on both the identity and the equality of the items it manages.
    /// The identity is determined by the item's hash, and equality is determined by whether the item's content has changed.
    /// If the content of an item is considered to have changed (even if its hash hasn't), the diffable data source may decide to reload that item.
    ///
    /// Calculate hash (identity) based on StatSection type and Row type
    /// If identity is equal particular cell reloads only if content changes
    func hash(into hasher: inout Hasher) {
        hasher.combine(statSection)
        hasher.combine(String(describing: type(of: self)))
    }
}
