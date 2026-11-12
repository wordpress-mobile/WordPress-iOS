import Foundation
import Synchronization
import Testing
@testable import AsyncImageKit

/// The prefetcher runs on `ImageDownloaderActor`, and so do these tests. A test
/// calls into the prefetcher, then calls `settle()` to let the actor run all the
/// work that call queued, so every check sees a finished state.
@Suite @ImageDownloaderActor struct ImagePrefetcherTests {
    private let fetcher = FakeImageFetcher()

    @Test func startsPrefetchesInOrderUpToTheLimit() async {
        let prefetcher = makePrefetcher(maxConcurrentTasks: 2)
        let requests = (0..<3).map { _ in makeRequest() }

        prefetcher.startPrefetching(for: requests)
        await settle()
        #expect(fetcher.running == requests.prefix(2).map(\.url))

        fetcher.finish(requests[0].url)
        await settle()
        #expect(fetcher.running == requests.suffix(2).map(\.url))
    }

    @Test func restartedPrefetchRuns() async {
        let prefetcher = makePrefetcher(maxConcurrentTasks: 1)
        let request = makeRequest()

        // GIVEN an image is being prefetched
        prefetcher.startPrefetching(for: [request])
        await settle()
        #expect(fetcher.started == [request.url])

        // WHEN prefetching stops and starts again before the first download finishes
        prefetcher.stopPrefetching(for: [request])
        prefetcher.startPrefetching(for: [request])
        await settle()
        #expect(fetcher.cancelled == [request.url])

        fetcher.finish(request.url)
        await settle()

        // THEN the image is prefetched again
        #expect(fetcher.started == [request.url, request.url], "The restarted prefetch never ran")
    }

    // MARK: - Helpers

    private func makePrefetcher(maxConcurrentTasks: Int) -> ImagePrefetcher {
        ImagePrefetcher(maxConcurrentTasks: maxConcurrentTasks) { [fetcher] request in
            await fetcher.fetch(request)
        }
    }

    private func makeRequest() -> ImageRequest {
        ImageRequest(url: URL(string: "https://example.com/\(UUID().uuidString).jpg")!)
    }

    /// Lets `ImageDownloaderActor` run everything queued on it.
    ///
    /// Each yield puts this test at the back of the actor's queue, so the jobs
    /// already queued run first. Every chain of work here is only a few jobs long.
    private func settle() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }
}

/// Stands in for the image downloader. Each prefetch stays running until the
/// test calls `finish(_:)`, even when it's cancelled, so the test decides the order.
private final class FakeImageFetcher: Sendable {
    private struct Fetch {
        let url: URL
        let continuation: CheckedContinuation<Void, Never>
    }

    private struct State {
        var started: [URL] = []
        var cancelled: [URL] = []
        var running: [Fetch] = []
    }

    private let state = Mutex(State())

    /// Every URL a prefetch started for, in order.
    var started: [URL] { state.withLock { $0.started } }

    /// Every URL a prefetch was cancelled for, in order.
    var cancelled: [URL] { state.withLock { $0.cancelled } }

    /// The URLs of the prefetches that haven't finished, in the order they started.
    var running: [URL] { state.withLock { $0.running.map(\.url) } }

    func fetch(_ request: ImageRequest, isolation: isolated (any Actor)? = #isolation) async {
        let url = request.url
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                state.withLock {
                    $0.started.append(url)
                    $0.running.append(Fetch(url: url, continuation: continuation))
                }
            }
        } onCancel: {
            state.withLock { $0.cancelled.append(url) }
        }
    }

    /// Finishes the oldest running prefetch for the URL.
    func finish(_ url: URL) {
        let fetch = state.withLock { state -> Fetch? in
            guard let index = state.running.firstIndex(where: { $0.url == url }) else {
                return nil
            }
            return state.running.remove(at: index)
        }
        #expect(fetch != nil, "No prefetch is running for \(url)")
        fetch?.continuation.resume()
    }
}

private extension ImageRequest {
    var url: URL { source.url! }
}
