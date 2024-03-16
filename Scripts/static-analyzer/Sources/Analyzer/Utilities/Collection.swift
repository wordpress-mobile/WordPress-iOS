
extension Sequence {

    /// Remove duplicates elements in the receiver, by using the value at given key path as the unique identifier.
    ///
    /// - Returns: A new array with duplicated elements removed.
    func removingDuplicates<Value: Hashable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        reduce(into: [Value: Element]()) { uniq, element in
            let key = element[keyPath: keyPath]
            uniq[key] = element
        }
        .values
        .map { $0 }
    }

}
