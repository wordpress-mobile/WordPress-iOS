import Foundation

/// Provides a sequence of incremental delays, repeating the last one
/// indefinitely.
///
public struct IncrementalDelay<Element> {
    public var current: Element

    private let delaySequence: AnySequence<Element>
    private var iterator: AnyIterator<Element>

    public init(_ sequence: [Element]) {
        precondition(!sequence.isEmpty, "IncrementalDelay sequence can't be empty")
        delaySequence = sequence.repeatingLast()
        iterator = delaySequence.makeIterator()
        current = iterator.next()!
    }

    public mutating func increment() {
        current = iterator.next()!
    }

    public mutating func reset() {
        iterator = delaySequence.makeIterator()
        current = iterator.next()!
    }
}
