import Foundation

extension Progress {

    /// Creates and returns progress object that is 100% completed.
    ///
    /// This is good to use on scenarios where tasks are small and quick and you want to just return a completed progress.
    ///
    /// - Returns: Progress object
    static func discreteCompletedProgress() -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        return progress
    }
}
