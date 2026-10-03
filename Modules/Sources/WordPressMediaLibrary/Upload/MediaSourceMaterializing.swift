import Foundation

/// Test seam over `UploadSourceMaterializer.materialize`. The actor talks
/// to materialization via this protocol so tests can substitute a mock.
protocol MediaSourceMaterializing: Sendable {
    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload
}

extension UploadSourceMaterializer: MediaSourceMaterializing {}
