import Foundation
import GutenbergKit
import WordPressCore
import WordPressData

/// Manages prefetched editor dependencies to enable fast editor loading.
///
/// When the user visits My Site, we prefetch editor dependencies in the background.
/// This manager stores those dependencies in memory so they can be passed directly
/// to `EditorViewController`, avoiding the async loading flow and progress bar.
///
/// ## Usage
///
/// ```swift
/// // Prefetch dependencies (e.g., in MySiteViewController)
/// Task {
///     await EditorDependencyManager.shared.prefetchDependencies(for: blog)
/// }
///
/// // Retrieve cached dependencies when opening editor
/// let dependencies = EditorDependencyManager.shared.dependencies(for: blog)
/// let editor = EditorViewController(configuration: config, dependencies: dependencies)
/// ```
///
final class EditorDependencyManager: Sendable {

    static let shared = EditorDependencyManager()

    /// Cached dependencies keyed by blog's ObjectID string representation.
    private let cache = LockingHashMap<EditorDependencies>()

    /// Tracks the `newGutenbergPlugins` flag value at the time the cache was last populated.
    /// Used to detect when the flag changes and invalidate all stale entries.
    private let pluginsFlagLock = NSLock()
    private var _lastPluginsFlagValue: Bool?

    /// Currently running prefetch tasks, keyed by blog's ObjectID string.
    private let prefetchTasks = LockingTaskHashMap<Void, Never>()

    /// Currently-running cache-clearing tasks
    private let invalidationTasks = LockingTaskHashMap<Void, Never>()

    private init() {}

    /// Returns cached dependencies for the given blog, if available.
    ///
    /// This method is thread-safe and can be called from any context, including
    /// synchronous initializers.
    ///
    /// - Parameter blog: The blog to get dependencies for.
    /// - Returns: Cached `EditorDependencies` if available, otherwise `nil`.
    func dependencies(for blog: Blog) -> EditorDependencies? {
        let key = cacheKey(for: blog)
        return cache[key]
    }

    /// Prefetches editor dependencies for the given blog in the background.
    ///
    /// If a prefetch is already in progress for this blog, this method returns immediately.
    /// The prefetched dependencies are stored in memory and can be retrieved later
    /// using `dependencies(for:)`.
    ///
    /// - Parameter blog: The blog to prefetch dependencies for.
    @MainActor
    func prefetchDependencies(for blog: Blog) async {
        await _prefetchDependencies(for: blog)?.value
    }

    /// Schedule prefetching editor dependencies for the given blog in the background.
    ///
    /// Prefer the `async` version of this method where possible.
    ///
    /// This method returns immediately — any results can be retrieved later
    /// using `dependencies(for:)`.
    ///
    /// - Parameter blog: The blog to prefetch dependencies for.
    @MainActor
    func prefetchDependencies(for blog: Blog) {
        _prefetchDependencies(for: blog)
    }

    @discardableResult
    private func _prefetchDependencies(for blog: Blog) -> Task<Void, Never>? {
        let key = cacheKey(for: blog)

        // Don't start a new prefetch if one is already running
        if prefetchTasks[key] != nil {
            return nil
        }

        // Check if the plugins flag changed since we last cached
        let currentPluginsFlagValue = RemoteFeatureFlag.newGutenbergPlugins.enabled()
        let lastFlagValue = pluginsFlagLock.withLock { _lastPluginsFlagValue }
        if let lastFlagValue, lastFlagValue != currentPluginsFlagValue {
            // Flag changed - invalidate all cached entries
            DDLogInfo("EditorDependencyManager: Plugins flag changed (\(lastFlagValue) -> \(currentPluginsFlagValue)), invalidating all cached dependencies")
            cache.removeAll()
            prefetchTasks.removeAll()
        }

        // Don't prefetch if we already have cached dependencies
        if cache[key] != nil {
            return nil
        }

        let configuration = EditorConfiguration(blog: blog)
        let service = EditorService(configuration: configuration)

        let task = Task {
            do {
                let dependencies = try await service.prepare()
                self.cache[key] = dependencies
                self.pluginsFlagLock.withLock { self._lastPluginsFlagValue = currentPluginsFlagValue }
            } catch {
                // Prefetch failed - editor will fall back to async loading
                DDLogError("EditorDependencyManager: Failed to prefetch dependencies: \(error)")
            }

            self.prefetchTasks.removeValue(forKey: key)
        }

        prefetchTasks[key] = task

        return task
    }

    /// Invalidates cached dependencies for the given blog.
    ///
    /// Call this when blog settings change or when you want to force a fresh fetch.
    ///
    /// `completion` is guaranteed to run on the main actor.
    ///
    /// - Parameter blog: The blog to invalidate cache for.
    @MainActor
    func invalidate(for blog: Blog, completion: @escaping () -> Void) {
        let key = cacheKey(for: blog)

        // Don't allow more than one concurrent invalidation
        if self.invalidationTasks[key] != nil {
            return
        }

        let configuration = EditorConfiguration(blog: blog)

        self.invalidationTasks[key] = Task {

            cache.removeValue(forKey: key)
            prefetchTasks.removeValue(forKey: key)

            do {
                try await EditorService(configuration: configuration).purge()
            } catch {
                DDLogError("EditorDependencyManager: Failed to clear cache: \(error)")
            }

            completion()
            self.invalidationTasks[key] = nil
        }
    }

    /// Clears all cached dependencies.
    func invalidateAll() {
        cache.removeAll()
        pluginsFlagLock.withLock { _lastPluginsFlagValue = nil }
        prefetchTasks.removeAll()
        // No need to use `removeAll` for the `invalidationTasks`
    }

    private func cacheKey(for blog: Blog) -> String {
        blog.objectID.uriRepresentation().absoluteString
    }
}
