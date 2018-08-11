import Foundation

extension BidirectionalCollection {
    public func lastIndex(where predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Index? {
        if let idx = try reversed().index(where: predicate) {
            return self.index(before: idx.base)
        }
        return nil
    }
}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
