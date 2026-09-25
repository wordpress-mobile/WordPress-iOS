import Foundation
import Testing

@testable import WordPress

/// Calls `tick()` directly instead of waiting for the observer's timer, so the
/// results don't depend on scheduling.
struct VideoSessionProgressObserverTests {

    @Test func reportsProgress() {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        let observer = VideoSessionProgressObserver(sessionProgress: { 0.4 }) { value in
            progress.completedUnitCount = Int64(100 * value)
        }
        defer { observer.stop() }

        observer.tick()

        #expect(progress.completedUnitCount == 40)
    }

    /// `MediaVideoExporter` stops the observer when the export ends, then marks
    /// the progress as finished if the export failed. A tick that was already
    /// queued must not overwrite that.
    @Test func doesNotReportAfterStop() {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        let observer = VideoSessionProgressObserver(sessionProgress: { 0.4 }) { value in
            progress.completedUnitCount = Int64(100 * value)
        }

        observer.stop()
        progress.completedUnitCount = progress.totalUnitCount
        observer.tick()

        #expect(progress.completedUnitCount == progress.totalUnitCount)
    }
}
