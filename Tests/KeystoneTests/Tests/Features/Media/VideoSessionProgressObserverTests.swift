import Foundation
import Testing

@testable import WordPress

struct VideoSessionProgressObserverTests {

    @Test func reportsProgressWhileRunning() async throws {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        let observer = VideoSessionProgressObserver(sessionProgress: { 0.4 }) { value in
            progress.completedUnitCount = Int64(100 * value)
        }
        defer { observer.stop() }

        try await Task.sleep(for: .milliseconds(300))

        #expect(progress.completedUnitCount == 40)
    }

    /// `MediaVideoExporter` stops the observer when the export ends, then marks
    /// the progress as finished if the export failed. A tick that was already
    /// queued must not overwrite that.
    @Test func doesNotReportAfterStop() async throws {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        let observer = VideoSessionProgressObserver(sessionProgress: { 0.4 }) { value in
            progress.completedUnitCount = Int64(100 * value)
        }

        observer.stop()
        progress.completedUnitCount = progress.totalUnitCount

        try await Task.sleep(for: .milliseconds(300))

        #expect(progress.completedUnitCount == progress.totalUnitCount)
    }
}
