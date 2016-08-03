import Foundation

extension CollectionType where Index: BidirectionalIndexType {

    /// Returns the last@ index where `predicate` returns `true` for the
    /// corresponding value, or `nil` if such value is not found.
    ///
    /// - Complexity: O(`self.count`).
    @warn_unused_result
    func lastIndexOf(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Index? {
        return try reverse().indexOf(predicate)?.base.predecessor()
    }
}
