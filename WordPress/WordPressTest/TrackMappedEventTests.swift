import Testing
import WordPressShared
import AutomatticTracks
import AutomatticTracksEvents

@testable import WordPress

struct TrackMappedEventTests {
    @Test func verifyTrackEventNameMapping() throws {
        for index in 0..<WPAnalyticsStat.maxValue.rawValue {
            let stat = try #require(WPAnalyticsStat(rawValue: index))
            if let map = TracksMappedEvent.make(for: stat) { // Some events are not mapped yet
                let event = AutomatticTracksEvents.TracksEvent()
                event.uuid = UUID()
                event.eventName = "wpios_\(map.name)"

                try event.validateObject()
            }
        }
    }
}
