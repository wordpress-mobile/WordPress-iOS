import Foundation

/// Downloader for `.remoteURL` materialization. Owns a private ephemeral
/// `URLSession` and is reused across downloads (the materializer holds one
/// instance), so downloaded media bytes, cookies, and credentials never
/// touch the app-wide `URLSession.shared` cache and jar.
///
/// Built on the async `URLSession.download(from:delegate:)`, so the runtime
/// owns the continuation, cancellation, temp-file delivery, and error
/// propagation. The only thing it can't give us is byte-level progress
/// (the async convenience methods suppress `didWriteData`), so we observe
/// the task's own `Progress` via KVO from `didCreateTask`, the workaround
/// Apple's URL Loading System team recommends for this case:
/// https://developer.apple.com/forums/thread/723015
final class RemoteDownloader: Sendable {

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        // Media downloads are large and single-use, so keep them out of the
        // session's in-memory URL cache.
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    /// Downloads `url` into `parentDir` and returns the local file URL. Reports
    /// byte-level progress on `progress` (scaled to its existing
    /// `totalUnitCount`). Cooperative task cancellation cancels the request and
    /// surfaces as `CancellationError`.
    func download(from url: URL, into parentDir: URL, progress: Progress) async throws -> URL {
        let delegate = ProgressForwardingDelegate(progress: progress)
        let location: URL
        let response: URLResponse
        do {
            (location, response) = try await session.download(from: url, delegate: delegate)
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw MaterializerError.remoteDownloadFailed(underlyingError: error)
        }

        // The async `download` hands back a temp file it does not reap for us,
        // so we own it now. Delete it on every path that doesn't move it into
        // parentDir (the status check below throws before the move), otherwise a
        // failed download strands bytes in the system temp directory. On success
        // the move renames it away first, leaving this a no-op.
        defer { try? FileManager.default.removeItem(at: location) }

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
            progress.completedUnitCount = Int64(
                (taskProgress.fractionCompleted * Double(progress.totalUnitCount)).rounded()
            )
        }
    }
}
