import Foundation

/// A simple queue, backed by a Swift Array.
/// Push and pop!
///
public struct Queue<Element> {
    private var elements = [Element]()

    /// Push `element` onto the back of the queue
    ///
    mutating func push(_ element: Element) {
        elements.insert(element, at: elements.startIndex)
    }

    /// Remove and return the item at the front of the queue
    ///
    mutating func pop() -> Element? {
        return elements.popLast()
    }
}
