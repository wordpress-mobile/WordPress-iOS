extension Array {
    /// Returns a sequence containing all the array elements, repeating the last
    /// one indefinitely.
    ///
    public func repeatingLast() -> AnySequence<Iterator.Element> {
        return AnySequence<Iterator.Element> { () -> AnyIterator<Iterator.Element> in
            var last: Iterator.Element? = nil
            var iter = self.makeIterator()
            return AnyIterator {
                last = iter.next() ?? last
                return last
            }
        }
    }
}

extension Array where Element: Hashable {
    public var unique: [Element] {
        return Array(Set(self))
    }
}


extension Array {
    /// Returns array containing only elements that have unique values for item at given KeyPath.
    /// Useful when you want to `unique` objects by their property, e.g. find all unique `author`s for a list of `Comment`s.
    ///
    /// - Parameter filteringKeyPath: A KeyPath to a `Hashable` property that the elements should be uniqued by.
    ///
    /// - Returns: Array with values filtered by using the given KeyPath to ensure only unique values are present.
    public func unique<Value: Hashable>(by filteringKeyPath: KeyPath<Element, Value>) -> [Element] {
        let values = self.map { $0[keyPath: filteringKeyPath] }

        let uniqueValues = values.unique
        let indices = uniqueValues.flatMap { values.index(of: $0) }

        return indices.map { self[$0] }
    }
}

extension Array where Element: Equatable {
    /// Returns an array of indices for the elements that are different than the
    /// corresponding element in the given array.
    ///
    public func differentIndices(_ other: [Element]) -> [Int] {
        return enumerated().flatMap({ (offset, value) -> Int? in
            guard offset < other.endIndex else {
                return offset
            }
            if value != other[offset] {
                return offset
            } else {
                return nil
            }
        })
    }
}
