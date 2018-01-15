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
