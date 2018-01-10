import Foundation

extension Progress {

    static func discreteCompletedProgress() -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        return progress
    }
}
