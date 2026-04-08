import Collections
import UIKit
import Vision

/// Detects the most salient (visually interesting) region in images using Vision framework.
/// Results are cached by image URL.
public actor ImageSaliencyService {
    public nonisolated static let shared = ImageSaliencyService()

    private nonisolated let cache = SaliencyCache()
    private nonisolated let detector = SaliencyDetector()
    private var inflightTasks: [URL: Task<CGRect?, Never>] = [:]

    init() {
        Task { [cache] in
            cache.loadFromDisk()
        }
    }

    /// Returns a cached rect synchronously without starting a task, or `nil` if not yet cached.
    public nonisolated func cachedSaliencyRect(for url: URL) -> CGRect? {
        cache.cachedRect(for: url)
    }

    /// Returns the bounding rect of the most salient region in UIKit normalized coordinates
    /// (origin top-left, values 0–1), or `nil` if detection fails or no salient objects are found.
    ///
    /// - warning: The underlying `Vision` framework works _only_ on the device.
    public func saliencyRect(for image: UIImage, url: URL) async -> CGRect? {
        if cache.isCached(for: url) {
            return cache.cachedRect(for: url)
        }
        if let existing = inflightTasks[url] {
            return await existing.value
        }
        let task = Task<CGRect?, Never> { [detector] in
            await detector.detect(in: image)
        }
        inflightTasks[url] = task
        let result = await task.value
        inflightTasks[url] = nil
        cache.store(result, for: url)
        return result
    }

    /// Returns the frame for the image view within a container such that `saliencyRect`
    /// appears at `topInset` points from the top. Returns `nil` when no adjustment is needed
    /// (i.e. the image is not portrait relative to the container).
    public nonisolated func adjustedFrame(
        saliencyRect: CGRect,
        imageSize: CGSize,
        in containerSize: CGSize,
        topInset: CGFloat = 16
    ) -> CGRect? {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return nil }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        // Only adjust for portrait images shown in a wider container.
        guard imageAspect < containerAspect else { return nil }

        // Scale to fill container width; the scaled height will exceed container height.
        let scale = containerSize.width / imageSize.width
        let scaledHeight = imageSize.height * scale

        let salientTopInScaled = saliencyRect.origin.y * scaledHeight
        let desiredY = topInset - salientTopInScaled

        // Clamp so the image always covers the full container without empty gaps.
        let minY = containerSize.height - scaledHeight  // negative
        let clampedY = min(0, max(minY, desiredY))

        return CGRect(x: 0, y: clampedY, width: containerSize.width, height: scaledHeight)
    }

}

/// Runs saliency detection serially — one image at a time.
private actor SaliencyDetector {
    func detect(in image: UIImage) -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let observation = request.results?.first,
              let salientObjects = observation.salientObjects,
              !salientObjects.isEmpty else {
            return nil
        }
        // Union all salient object bounding boxes.
        // Vision coordinates: origin at bottom-left, Y increases upward.
        let union = salientObjects.reduce(CGRect.null) { $0.union($1.boundingBox) }
        // Convert to UIKit coordinates (origin at top-left, Y increases downward).
        return CGRect(
            x: union.origin.x,
            y: 1.0 - union.origin.y - union.height,
            width: union.width,
            height: union.height
        )
    }
}

private final class SaliencyCache: @unchecked Sendable {
    private var store: OrderedDictionary<String, CGRect?> = [:]
    private let lock = NSLock()
    private var isDirty = false
    private var observer: AnyObject?

    private static let maxCount = 1000
    private static let diskURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("saliency_cache.json")
    }()

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task.detached(priority: .utility) { self.saveToDisk() }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func isCached(for url: URL) -> Bool {
        lock.withLock { store[url.absoluteString] != nil }
    }

    func cachedRect(for url: URL) -> CGRect? {
        lock.withLock { store[url.absoluteString] ?? nil }
    }

    func store(_ rect: CGRect?, for url: URL) {
        lock.withLock {
            let key = url.absoluteString
            store.updateValue(rect, forKey: key)
            if store.count > Self.maxCount, let oldest = store.keys.first {
                store.removeValue(forKey: oldest)
            }
            isDirty = true
        }
    }

    func loadFromDisk() {
        guard let data = try? Data(contentsOf: Self.diskURL),
              let decoded = try? JSONDecoder().decode([String: CGRect?].self, from: data) else {
            return
        }
        lock.withLock {
            store = OrderedDictionary(uniqueKeysWithValues: decoded.map { ($0.key, $0.value) })
        }
    }

    func saveToDisk() {
        let snapshot: OrderedDictionary<String, CGRect?>? = lock.withLock {
            guard isDirty else { return nil }
            isDirty = false
            return store
        }
        guard let snapshot else { return }
        let dict = snapshot.reduce(into: [String: CGRect?]()) { $0[$1.key] = $1.value }
        guard let data = try? JSONEncoder().encode(dict) else { return }
        try? data.write(to: Self.diskURL, options: .atomic)
    }
}
