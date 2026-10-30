import Foundation

/// Waits without a deadline. Other tests share the main actor, so any fixed deadline fails on a
/// busy machine. The suite's time limit catches hangs by cancelling the sleep.
@MainActor
func waitUntil(_ condition: () -> Bool) async throws {
    while !condition() {
        try await Task.sleep(for: .milliseconds(5))
    }
}
