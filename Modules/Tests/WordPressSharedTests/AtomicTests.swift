import Foundation
import Testing
import WordPressShared

struct AtomicTests {
    @Test func storesAndLoadsWrappedValue() {
        var atomic = Atomic(wrappedValue: 10)
        #expect(atomic.wrappedValue == 10)

        atomic.wrappedValue = 42
        #expect(atomic.wrappedValue == 42)
    }

    @Test func concurrentAccessIsSafeUnderContention() {
        final class Box: @unchecked Sendable {
            var atomic = Atomic(wrappedValue: 0)
        }
        let box = Box()
        // Hammer the wrapper with concurrent readers and writers. The internal
        // NSLock must serialize access so the run finishes without a crash or a
        // torn read, leaving a value that was actually written.
        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            if iteration.isMultiple(of: 2) {
                box.atomic.wrappedValue = (iteration % 5) + 1
            } else {
                _ = box.atomic.wrappedValue
            }
        }
        #expect((0...5).contains(box.atomic.wrappedValue))
    }

    @Test func copyDoesNotShareValueStorage() {
        var original = Atomic(wrappedValue: 1)
        var copy = original

        copy.wrappedValue = 99
        #expect(original.wrappedValue == 1)
        #expect(copy.wrappedValue == 99)

        original.wrappedValue = 7
        #expect(original.wrappedValue == 7)
        #expect(copy.wrappedValue == 99)
    }

    @Test func loadReturnsSameReferenceForClassValues() {
        final class Ref {}
        let a = Ref()
        let b = Ref()

        var atomic = Atomic(wrappedValue: a)
        #expect(atomic.wrappedValue === a)

        atomic.wrappedValue = b
        #expect(atomic.wrappedValue === b)
        #expect(atomic.wrappedValue !== a)
    }

    @Test func supportsOptionalWrappedValueIncludingNil() {
        var atomic = Atomic<Int?>(wrappedValue: nil)
        #expect(atomic.wrappedValue == nil)

        atomic.wrappedValue = 5
        #expect(atomic.wrappedValue == 5)

        atomic.wrappedValue = nil
        #expect(atomic.wrappedValue == nil)
    }
}
