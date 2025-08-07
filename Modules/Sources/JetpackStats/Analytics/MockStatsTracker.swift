import Foundation

/// A no-op implementation of StatsTracker for testing and development
final class MockStatsTracker: StatsTracker, Sendable {
    static let shared = MockStatsTracker()

    private init() {}

    func send(_ event: StatsEvent, properties: [String: String]) {
#if DEBUG
        // In debug builds, print events to console for debugging
        debugPrint("[StatsTracker] Event: \(event) \(properties)")
#endif
    }
}
