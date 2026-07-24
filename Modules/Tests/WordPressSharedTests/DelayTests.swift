import Testing
@testable import WordPressShared

struct DelayTests {
    @Test func testIncrementalDelay() {
        var delay = IncrementalDelay([1, 5, 20, 60])
        #expect(1 == delay.current)
        delay.increment()
        #expect(5 == delay.current)
        delay.increment()
        #expect(20 == delay.current)
        delay.increment()
        #expect(60 == delay.current)
        delay.increment()
        #expect(60 == delay.current)
        delay.reset()
        #expect(1 == delay.current)
        delay.increment()
        #expect(5 == delay.current)
        delay.reset()
        #expect(1 == delay.current)
    }
}
