import Foundation

extension Collection where Index: Comparable {

    /// Returns the last@ index where `predicate` returns `true` for the
    /// corresponding value, or `nil` if such value is not found.
    ///
    /// - Complexity: O(`self.count`).
    
    func lastIndexOf(predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Index? {
        return try <#T##BidirectionalCollection corresponding to your index##BidirectionalCollection#>.index(before: reversed().index(where: predicate)?.base)
    }
}
