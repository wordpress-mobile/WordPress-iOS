import Foundation
import GutenbergKit
import os
import WordPressCore
import WordPressData
@preconcurrency import Combine

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

    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State: Sendable {
        var cache: [CacheKey: EditorDependencies] = [:]
        var prefetchTasks: [CacheKey: Task<Void, Never>] = [:]
        var invalidationTasks: [TaggedManagedObjectID<Blog>: Task<Void, Never>] = [:]
        var capabilityTasks: [TaggedManagedObjectID<Blog>: Task<Void, Never>] = [:]
        var featureFlagObserver: AnyCancellable?
    }

    private struct CacheKey: Hashable, Sendable {
        let blogID: TaggedManagedObjectID<Blog>
        let postType: PostTypeDetails

        init(blog: Blog, postType: PostTypeDetails) {
            self.blogID = TaggedManagedObjectID(blog)
            self.postType = postType
        }
    }

    private init() {
        state.withLock {
            $0.featureFlagObserver = NotificationCenter.default
                .publisher(for: FeatureFlagOverrideStore.didChangeNotification)
                .filter {
                    ($0.userInfo?[FeatureFlagOverrideStore.notificationFeatureFlagKey] as? RemoteFeatureFlag) == .newGutenberg
                }
                .sink { [weak self] _ in
                    Task {
                        await self?.invalidateAll()
                    }
                }
        }
    }

    /// Returns cached dependencies for the given blog, if available.
    ///
    /// This method is thread-safe and can be called from any context, including
    /// synchronous initializers.
    ///
    /// - Parameter blog: The blog to get dependencies for.
    /// - Returns: Cached `EditorDependencies` if available, otherwise `nil`.
    func dependencies(for blog: Blog, postType: PostTypeDetails) -> EditorDependencies? {
        let key = CacheKey(blog: blog, postType: postType)
        return state.withLock { $0.cache[key] }
    }

    /// Prefetches editor dependencies for the given blog in the background.
    ///
    /// If a prefetch is already in progress for this blog, this method returns immediately.
    /// The prefetched dependencies are stored in memory and can be retrieved later
    /// using `dependencies(for:)`.
    ///
    /// - Parameter blog: The blog to prefetch dependencies for.
    @MainActor
    func prefetchDependencies(for blog: Blog, postType: PostTypeDetails) async {
        await _prefetchDependencies(for: blog, postType: postType)?.value
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
    func prefetchDependencies(for blog: Blog, postType: PostTypeDetails) {
        _prefetchDependencies(for: blog, postType: postType)
    }

    @discardableResult
    private func _prefetchDependencies(for blog: Blog, postType: PostTypeDetails) -> Task<Void, Never>? {
        let key = CacheKey(blog: blog, postType: postType)

        let shouldStartPrefetch = state.withLock { state -> Bool in
            if state.prefetchTasks[key] != nil {
                return false
            }

            if state.cache[key] != nil {
                return false
            }

            return true
        }

        guard shouldStartPrefetch else {
            return nil
        }

        let configuration = EditorConfiguration(blog: blog, postType: postType)
        let service = EditorService(configuration: configuration)

        let task = Task {
            do {
                let dependencies = try await service.prepare()
                self.state.withLock { state in
                    state.cache[key] = dependencies
                }
            } catch {
                DDLogError("EditorDependencyManager: Failed to prefetch dependencies: \(error)")
            }

            _ = self.state.withLock { state in
                state.prefetchTasks.removeValue(forKey: key)
            }
        }

        state.withLock { state in
            state.prefetchTasks[key] = task
        }

        return task
    }

    /// Invalidates cached dependencies for the given blog.
    ///
    /// Call this when blog settings change or when you want to force a fresh fetch.
    ///
    /// `completion` is guaranteed to run on the main actor.
    ///
    /// - Parameter blog: The blog to invalidate cache for.
    func invalidate(for blogID: TaggedManagedObjectID<Blog>) async {
        let shouldStart = state.withLock {
            $0.invalidationTasks[blogID] == nil
        }

        guard shouldStart else {
            return
        }

        let task = Task {
            await _invalidate(for: blogID)

            self.state.withLock { state in
                _ = state.invalidationTasks.removeValue(forKey: blogID)
            }
        }

        state.withLock { state in
            state.invalidationTasks[blogID] = task
        }

        await task.value
    }

    private func _invalidate(for blogID: TaggedManagedObjectID<Blog>) async {
        let keysToInvalidate = self.state.withLock { state in
            let keys = state.cache.keys.filter { $0.blogID == blogID }

            for key in keys {
                state.prefetchTasks[key]?.cancel()
                state.cache.removeValue(forKey: key)
                state.prefetchTasks.removeValue(forKey: key)
            }

            return keys
        }

        let configurations: [EditorConfiguration]
        do {
            configurations = try await ContextManager.shared.performQuery { context in
                let blog = try context.existingObject(with: blogID)
                return keysToInvalidate.map { EditorConfiguration(blog: blog, postType: $0.postType) }
            }
        } catch {
            DDLogError("Failed to find blog for \(blogID): \(error)")
            return
        }

        for configuration in configurations {
            do {
                try await EditorService(configuration: configuration).purge()
            } catch {
                DDLogError("EditorDependencyManager: Failed to clear cache for \(configuration.postType.postType): \(error)")
            }
        }
    }

    /// Clears all cached dependencies.
    func invalidateAll() async {
        let blogIDs = state.withLock { state in
            Set(state.cache.keys.map(\.blogID))
        }

        for blogID in blogIDs {
            await invalidate(for: blogID)
        }
    }

    /// Query the server for its editor capabilities, and update the local editor settings store with the result.
    ///
    @MainActor
    public func fetchEditorCapabilities(for blog: Blog) async throws {
        let site = try WordPressSite(blog: blog)
        let client = WordPressClientFactory.shared.instance(for: site)

        var siteId: Int? = nil

        if case .dotCom(_, let _siteId, _) = site {
            siteId = _siteId
        }

        let hasBlockTheme = try await client.supports(.blockTheme, forSiteId: siteId)
        let hasBlockSettings = try await client.supports(.blockEditorSettings, forSiteId: siteId)
        let supportsPlugins = try await client.supports(.plugins, forSiteId: siteId)

        GutenbergSettings()
            .setSupports(.blockEditorSettings, hasBlockSettings, for: blog)
            .setSupports(.blockTheme, hasBlockTheme, for: blog)
            .setSupports(.plugins, supportsPlugins, for: blog)
    }

    /// Query the server for its editor capabilities, and update the local editor settings store with the result.
    ///
    /// Returns immediately and ignores errors – prefer the `async` version of this method.
    ///
    public func fetchEditorCapabilities(for blog: Blog) {
        let blogID = TaggedManagedObjectID(blog)

        let isAlreadyRunning = state.withLock { state in
            state.capabilityTasks[blogID] != nil
        }

        guard !isAlreadyRunning else {
            return
        }

        let task = Task {
            do {
                try await self.fetchEditorCapabilities(for: blog)
            } catch {
                DDLogError("EditorDependencyManager: Failed to fetch editor capabilities: \(error)")
            }

            self.state.withLock { state in
                _ = state.capabilityTasks.removeValue(forKey: blogID)
            }
        }

        state.withLock { state in
            state.capabilityTasks[blogID] = task
        }
    }
}
