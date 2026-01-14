import Foundation
import GutenbergKit
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
@MainActor
final class EditorDependencyManager {

    static let shared = EditorDependencyManager()

    /// Cached dependencies keyed by blog's ObjectID string representation.
    private var cache: [String: EditorDependencies] = [:]

    /// Currently running prefetch tasks, keyed by blog's ObjectID string.
    private var prefetchTasks: [String: Task<Void, Never>] = [:]

    private init() {}

    /// Returns cached dependencies for the given blog, if available.
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
    func prefetchDependencies(for blog: Blog) async {
        let key = cacheKey(for: blog)

        // Don't start a new prefetch if one is already running
        if prefetchTasks[key] != nil {
            return
        }

        // Don't prefetch if we already have cached dependencies
        if cache[key] != nil {
            return
        }

        let configuration = EditorConfiguration(blog: blog)
        let service = EditorService(configuration: configuration)

        let task = Task {
            do {
                let dependencies = try await service.prepare { _ in }
                self.cache[key] = dependencies
            } catch {
                // Prefetch failed - editor will fall back to async loading
                DDLogError("EditorDependencyManager: Failed to prefetch dependencies: \(error)")
            }
            self.prefetchTasks.removeValue(forKey: key)
        }

        prefetchTasks[key] = task
        await task.value
    }

    /// Invalidates cached dependencies for the given blog.
    ///
    /// Call this when blog settings change or when you want to force a fresh fetch.
    ///
    /// - Parameter blog: The blog to invalidate cache for.
    func invalidate(for blog: Blog) {
        let key = cacheKey(for: blog)
        cache.removeValue(forKey: key)
        prefetchTasks[key]?.cancel()
        prefetchTasks.removeValue(forKey: key)
    }

    /// Clears all cached dependencies.
    func invalidateAll() {
        cache.removeAll()
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }

    private func cacheKey(for blog: Blog) -> String {
        blog.objectID.uriRepresentation().absoluteString
    }
}
