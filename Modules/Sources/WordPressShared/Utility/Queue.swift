import Foundation

/// A simple queue, backed by a Swift Array.
/// Push and pop!
///
public struct Queue<Element> {
    private var elements = [Element]()

    public init() {}

    /// Push `element` onto the back of the queue
    ///
    public mutating func push(_ element: Element) {
        elements.insert(element, at: elements.startIndex)
    }

    /// Remove and return the item at the front of the queue
    ///
    public mutating func pop() -> Element? {
        elements.popLast()
    }

    /// Removes all elements; If `where` is given, only the elements matching the
    /// predicate will be removed.
    public mutating func removeAll(where shouldBeRemoved: ((Element) -> Bool)? = nil) {
        if let shouldBeRemoved {
            elements.removeAll(where: shouldBeRemoved)
        } else {
            elements.removeAll()
        }
    }
}
