import Foundation
import Collections

@ImageDownloaderActor
public final class ImagePrefetcher {
    private let fetch: @ImageDownloaderActor @Sendable (ImageRequest) async -> Void
    private let maxConcurrentTasks: Int
    private var queue = OrderedDictionary<PrefetchKey, PrefetchTask>()
    private var numberOfActiveTasks = 0

    deinit {
        let tasks = queue.values.compactMap(\.task)
        for task in tasks {
            task.cancel()
        }
    }

    public nonisolated convenience init(
        downloader: ImageDownloader = .shared,
        maxConcurrentTasks: Int = 2
    ) {
        self.init(maxConcurrentTasks: maxConcurrentTasks) { request in
            _ = try? await downloader.image(for: request)
        }
    }

    /// - parameter fetch: Prefetches the image for the request. Tests pass their own to control when each prefetch finishes.
    nonisolated init(
        maxConcurrentTasks: Int,
        fetch: @escaping @ImageDownloaderActor @Sendable (ImageRequest) async -> Void
    ) {
        self.fetch = fetch
        self.maxConcurrentTasks = maxConcurrentTasks
    }

    public nonisolated func startPrefetching(for requests: [ImageRequest]) {
        Task { @ImageDownloaderActor in
            for request in requests {
                startPrefetching(for: request)
            }
            performPendingTasks()
        }
    }

    private func startPrefetching(for request: ImageRequest) {
        let key = PrefetchKey(request: request)
        guard queue[key] == nil else {
            return
        }
        queue[key] = PrefetchTask()
    }

    private func performPendingTasks() {
        var index = 0
        func nextPendingTask() -> (PrefetchKey, PrefetchTask)? {
            while index < queue.count {
                if queue.elements[index].value.task == nil {
                    return queue.elements[index]
                }
                index += 1
            }
            return nil
        }
        while numberOfActiveTasks < maxConcurrentTasks, let (key, prefetch) = nextPendingTask() {
            prefetch.task = Task {
                await self.actuallyPrefetchImage(prefetch, for: key)
            }
            numberOfActiveTasks += 1
        }
    }

    private func actuallyPrefetchImage(_ prefetch: PrefetchTask, for key: PrefetchKey) async {
        await fetch(key.request)

        numberOfActiveTasks -= 1
        // If this prefetch was stopped and the image was queued again while it ran,
        // the queue holds a new prefetch for the same key. Leave that one alone.
        if queue[key] === prefetch {
            queue[key] = nil
        }
        performPendingTasks()
    }

    public nonisolated func stopPrefetching(for requests: [ImageRequest]) {
        Task { @ImageDownloaderActor in
            for request in requests {
                stopPrefetching(for: request)
            }
            performPendingTasks()
        }
    }

    private func stopPrefetching(for request: ImageRequest) {
        let key = PrefetchKey(request: request)
        if let task = queue.removeValue(forKey: key) {
            task.task?.cancel()
        }
    }

    public nonisolated func stopAll() {
        Task { @ImageDownloaderActor in
            for (_, value) in queue {
                value.task?.cancel()
            }
            // Don't reset `numberOfActiveTasks`: each cancelled prefetch counts
            // itself out when its download stops.
            queue.removeAll()
        }
    }

    private struct PrefetchKey: Hashable, Sendable {
        let request: ImageRequest

        func hash(into hasher: inout Hasher) {
            request.source.url?.hash(into: &hasher)
        }

        static func == (lhs: PrefetchKey, rhs: PrefetchKey) -> Bool {
            let (lhs, rhs) = (lhs.request, rhs.request)
            return (lhs.source.url, lhs.options) == (rhs.source.url, rhs.options)
        }
    }

    private final class PrefetchTask: @unchecked Sendable {
        var task: Task<Void, Error>?
    }
}
