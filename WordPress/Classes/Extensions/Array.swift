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

extension Array {
    /// Returns an array of [(Value, [Element])] resulting of grouping the sorted elements
    /// of the original array by Value.
    ///
    public func sortedGroup<Value: Equatable>(keyPath: KeyPath<Element, Value>) -> [(Value, [Element])] {
        var currentValue: Value?
        var currentGroup = [Element]()
        var result = [(Value, [Element])]()
        forEach { (element) in
            let value = element[keyPath: keyPath]
            if currentValue != value {
                if let currentValue = currentValue {
                    result.append((currentValue, currentGroup))
                }
                currentValue = value
                currentGroup = []
            }
            currentGroup.append(element)
        }
        if let currentValue = currentValue {
            result.append((currentValue, currentGroup))
        }
        return result
    }
}
