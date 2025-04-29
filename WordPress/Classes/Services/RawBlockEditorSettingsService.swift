import Foundation
import WordPressKit
import WordPressShared

class RawBlockEditorSettingsService {
    private let blog: Blog
    private let remoteAPI: WordPressOrgRestApi
    private var isRefreshing: Bool = false
    private var refreshTask: Task<[String: Any], Error>?

    init?(blog: Blog) {
        guard let remoteAPI = WordPressOrgRestApi(blog: blog) else {
            return nil
        }

        self.blog = blog
        self.remoteAPI = remoteAPI
    }

    @MainActor
    private func fetchSettingsFromAPI() async throws -> [String: Any] {
        let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
        switch result {
        case .success(let response):
            guard let dictionary = response as? [String: Any] else {
                throw NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            let objectID = TaggedManagedObjectID(blog)
            try? await ContextManager.shared.performAndSave { context in
                let blog = try context.existingObject(with: objectID)
                blog.setBlockEditorSettings(dictionary)
            }
            return dictionary
        case .failure(let error):
            throw error
        }
    }

    /// Refreshes the editor settings in the background.
    func refreshSettings() {
        Task { @MainActor in
            try? await fetchSettings()
        }
    }

    @MainActor
    private func fetchSettings() async throws -> [String: Any] {
        if let task = refreshTask {
            return try await task.value
        }
        let task = Task { @MainActor in
            defer { refreshTask = nil }
            do {
                return try await fetchSettingsFromAPI()
            } catch {
                DDLogError("Error refreshing block editor settings: \(error)")
                throw error
            }
        }
        refreshTask = task
        return try await task.value
    }

    /// Returns cached settings if available. If not, fetches the settings from
    /// the network.
    @MainActor
    func getSettings() async throws -> [String: Any] {
        // Return cached settings if available
        if let cachedSettings = blog.getBlockEditorSettings() {
            return cachedSettings
        }
        return try await fetchSettings()
    }
}
