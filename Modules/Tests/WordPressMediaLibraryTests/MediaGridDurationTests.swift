import Testing
@testable import WordPressMediaLibrary

struct MediaGridDurationTests {
    @Test func zeroSeconds() {
        #expect(MediaGridDuration.string(forSeconds: 0) == "0:00")
    }

    @Test func underOneMinute() {
        #expect(MediaGridDuration.string(forSeconds: 7) == "0:07")
    }

    @Test func ninetySeconds() {
        #expect(MediaGridDuration.string(forSeconds: 90) == "1:30")
    }

    @Test func justUnderOneHour() {
        #expect(MediaGridDuration.string(forSeconds: 3599) == "59:59")
    }

    @Test func exactlyOneHour() {
        #expect(MediaGridDuration.string(forSeconds: 3600) == "1:00:00")
    }

    @Test func overOneHour() {
        #expect(MediaGridDuration.string(forSeconds: 3661) == "1:01:01")
    }
}
