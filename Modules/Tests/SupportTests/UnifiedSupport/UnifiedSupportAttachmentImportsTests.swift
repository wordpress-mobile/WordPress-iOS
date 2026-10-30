import Foundation
import Testing
@testable import Support

@MainActor
struct UnifiedSupportAttachmentImportsTests {

    /// A file that arrives after the reply form is closed has nowhere to go, so the import is stopped instead.
    @Test func stopsTheImportsStillRunning() async {
        let imports = UnifiedSupportAttachmentImports()
        let anImport = RunningImport()

        await withCheckedContinuation { hasStarted in
            imports.start {
                hasStarted.resume()
                try? await Task.sleep(for: .seconds(30))
                anImport.wasCancelled = Task.isCancelled
                anImport.hasFinished?.resume()
            }
        }

        await withCheckedContinuation { hasFinished in
            anImport.hasFinished = hasFinished
            imports.cancelAll()
        }

        #expect(anImport.wasCancelled)
    }

    /// Stopping the imports of a form that closed must not stop the ones the next form starts.
    @Test func runsAnImportStartedAfterTheLastOnesWereStopped() async {
        let imports = UnifiedSupportAttachmentImports()
        imports.cancelAll()

        let hasRun = await withCheckedContinuation { continuation in
            imports.start {
                continuation.resume(returning: !Task.isCancelled)
            }
        }

        #expect(hasRun)
    }

    @MainActor
    private final class RunningImport {
        var wasCancelled = false
        var hasFinished: CheckedContinuation<Void, Never>?
    }
}
