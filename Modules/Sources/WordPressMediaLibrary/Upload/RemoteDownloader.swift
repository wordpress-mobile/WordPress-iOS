import Foundation

/// Single-use downloader for `.remoteURL` materialization. The materializer
/// constructs one per download and discards it after.
///
/// Built on the async `URLSession.download(from:delegate:)`, so the runtime
/// owns the continuation, cancellation, temp-file delivery, and error
/// propagation. The only thing it can't give us is byte-level progress
/// (the async convenience methods suppress `didWriteData`), so we observe
/// the task's own `Progress` via KVO from `didCreateTask`, the workaround
/// Apple's URL Loading System team recommends for this case:
/// https://developer.apple.com/forums/thread/723015
final class RemoteDownloader {

    /// Downloads `url` into `parentDir` and returns the local file URL. Reports
    /// byte-level progress on `progress` (mapped to its existing 0-100
    /// `totalUnitCount`). Cooperative task cancellation cancels the request and
    /// surfaces as `CancellationError`.
    func download(from url: URL, into parentDir: URL, progress: Progress) async throws -> URL {
        let delegate = ProgressForwardingDelegate(progress: progress)
        let location: URL
        let response: URLResponse
        do {
            (location, response) = try await URLSession.shared.download(from: url, delegate: delegate)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch {
            throw MaterializerError.remoteDownloadFailed(underlyingError: error)
        }

        // HTTP status check: a 404/500 response body looks like a successful
        // download to URLSession (it still hands back a valid temp file). For
        // Stock Photos the image-byte validator catches HTML error bodies
        // later, but remote GIFs are a raw passthrough, so without this we'd
        // happily upload an HTML 404 response as 'image/gif'.
        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            let statusError = NSError(
                domain: "RemoteDownloader",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode) response"]
            )
            throw MaterializerError.remoteDownloadFailed(underlyingError: statusError)
        }

        // Move out of the system temp location (reaped after this call) into our
        // owned parentDir, reusing the system-generated unique name.
        let dest = parentDir.appendingPathComponent(location.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
        } catch {
            throw MaterializerError.remoteDownloadFailed(underlyingError: error)
        }
        return dest
    }
}

/// Forwards the download task's `Progress` to the caller-supplied `progress`.
/// `didCreateTask` fires for the async download API (unlike `didWriteData`),
/// so it's the hook for installing the KVO observation.
private final class ProgressForwardingDelegate: NSObject, URLSessionTaskDelegate {
    private let progress: Progress
    private var observation: NSKeyValueObservation?

    init(progress: Progress) {
        self.progress = progress
        super.init()
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        observation = task.progress.observe(\.fractionCompleted) { [progress] taskProgress, _ in
            // `fractionCompleted` stays 0 when the server sends no Content-Length
            // (totalUnitCount is -1), leaving the row indeterminate until the
            // upload phase drives it to completion.
            progress.completedUnitCount = Int64((taskProgress.fractionCompleted * 100).rounded())
        }
    }
}
