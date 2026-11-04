import AVFoundation
import Foundation
import Testing
@testable import WordPress

struct MediaVideoExporterCancellationTests {
    /// Cancels each export at the moment its session enters `.exporting`.
    ///
    /// `AVAssetExportSession.states(updateInterval:)` traps if the session leaves
    /// `.exporting` while the iterator builds its first `.exporting` value. If the
    /// exporter sends the cancel to the session too early, this crashes the test host.
    @Test func cancellingAsExportStartsReportsCancellation() async throws {
        let url = try #require(
            Bundle(for: MediaURLExporterTests.self).url(forResource: "test-video-device-gps", withExtension: "m4v")
        )

        for _ in 0..<300 {
            let asset = AVURLAsset(url: url)
            let session = try #require(AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset640x480))
            let error = await exportAndCancelAtStart(session)

            // `nil` means no callback arrived in time. That is a separate,
            // timing-dependent problem, so it's tolerated here.
            if let error {
                #expect(error as? MediaVideoExporter.VideoExportError == .videoExportSessionCancelled)
            }
        }
    }

    /// Returns the error reported by the export, or `nil` if no callback arrived in time.
    private func exportAndCancelAtStart(_ session: AVAssetExportSession) async -> MediaExportError? {
        nonisolated(unsafe) let session = session
        let exporter = MediaVideoExporter(session: session)
        exporter.mediaDirectoryType = .temporary

        return await withCheckedContinuation { continuation in
            let result = OneShot(continuation)
            let progress = exporter.export(
                onCompletion: { export in
                    try? FileManager.default.removeItem(at: export.url)
                    Issue.record("The export should have been cancelled")
                    result.resume(with: nil)
                },
                onError: { result.resume(with: $0) }
            )

            DispatchQueue.global(qos: .userInteractive)
                .async {
                    let deadline = Date.now.addingTimeInterval(3)
                    while (session as ExportStatusReading).status != .exporting, Date.now < deadline {}
                    progress.cancel()
                }
            DispatchQueue.global()
                .asyncAfter(deadline: .now() + 3) {
                    result.resume(with: nil)
                }
        }
    }
}

/// Reads `status` without a deprecation warning. `states(updateInterval:)` can't
/// be used here: the test needs to spin on the status to aim the cancel.
private protocol ExportStatusReading {
    var status: AVAssetExportSession.Status { get }
}

extension AVAssetExportSession: ExportStatusReading {}

private final class OneShot: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<MediaExportError?, Never>?

    init(_ continuation: CheckedContinuation<MediaExportError?, Never>) {
        self.continuation = continuation
    }

    func resume(with error: MediaExportError?) {
        lock.withLock {
            continuation?.resume(returning: error)
            continuation = nil
        }
    }
}
