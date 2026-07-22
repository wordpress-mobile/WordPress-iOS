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
}
