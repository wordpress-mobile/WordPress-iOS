import Foundation
import Testing
import WordPressShared

struct ProgressHelpersTests {
    @Test func discreteCompletedProgressIsFullyComplete() {
        let progress = Progress.discreteCompletedProgress()
        #expect(progress.isFinished)
        #expect(progress.totalUnitCount == 1)
        #expect(progress.completedUnitCount == progress.totalUnitCount)
        #expect(progress.fractionCompleted == 1.0)
    }

    @Test func eachCallReturnsDistinctIndependentInstance() {
        let first = Progress.discreteCompletedProgress()
        let second = Progress.discreteCompletedProgress()
        // Distinct reference identities, not a shared instance.
        #expect(first !== second)
        // Mutating one must not affect the other.
        first.completedUnitCount = 0
        #expect(first.fractionCompleted == 0.0)
        #expect(first.isFinished == false)
        #expect(second.completedUnitCount == 1)
        #expect(second.fractionCompleted == 1.0)
        #expect(second.isFinished)
    }

    @Test func completedProgressIsDeterminate() {
        let progress = Progress.discreteCompletedProgress()
        #expect(progress.isIndeterminate == false)
    }

    @Test func discreteProgressDoesNotAttachToCurrentParent() {
        let parent = Progress.discreteProgress(totalUnitCount: 1)
        parent.becomeCurrent(withPendingUnitCount: 1)
        let child = Progress.discreteCompletedProgress()
        // While the parent is still current: a discrete child does not attach to
        // it, so the parent has not absorbed the child's completion. A plain
        // Progress(totalUnitCount:) child would have attached and consumed the
        // pending unit, pushing the parent to 1.0 here.
        #expect(parent.completedUnitCount == 0)
        #expect(parent.fractionCompleted == 0.0)
        parent.resignCurrent()
        // The returned child is independently complete regardless.
        #expect(child.isFinished)
        #expect(child.fractionCompleted == 1.0)
    }

    @Test func completedProgressIsNotCancelledOrPaused() {
        let progress = Progress.discreteCompletedProgress()
        #expect(progress.isCancelled == false)
        #expect(progress.isPaused == false)
    }
}
