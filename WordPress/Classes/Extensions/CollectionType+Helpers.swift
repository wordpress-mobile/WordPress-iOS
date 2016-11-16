import Foundation

extension BidirectionalCollection {
    public func lastIndex(where predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Index? {
        if let idx = try reversed().index(where: predicate) {
            return self.index(before: idx.base)
        }
        return nil
    }
}
