import Testing
import WordPressShared

struct AtomicTests {
    @Test func storesAndLoadsWrappedValue() {
        var atomic = Atomic(wrappedValue: 10)
        #expect(atomic.wrappedValue == 10)

        atomic.wrappedValue = 42
        #expect(atomic.wrappedValue == 42)
    }
}
