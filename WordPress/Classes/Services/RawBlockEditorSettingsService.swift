import Foundation
import WordPressData
import WordPressKit
import WordPressShared

final class RawBlockEditorSettingsService {

    private let blog: Blog
    private var refreshTask: Task<Data, Error>?
    private let dotOrgRestAPI: WordPressOrgRestApi

    init(blog: Blog) {
        self.blog = blog
        self.dotOrgRestAPI = WordPressOrgRestApi(blog: blog)!
    }

    private static var services: [TaggedManagedObjectID<Blog>: RawBlockEditorSettingsService] = [:]

    @MainActor
    static func getService(forBlog blog: Blog) -> RawBlockEditorSettingsService {
        let objectID = TaggedManagedObjectID(blog)
        if let service = services[objectID] {
            return service
        }
        let service = RawBlockEditorSettingsService(blog: blog)
        services[objectID] = service
        return service
    }

    /// Refreshes the editor settings in the background.
    func refreshSettings() {
        Task { @MainActor in
            try? await fetchSettings()
        }
    }

    @MainActor
    private func fetchSettings() async throws -> Data {
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

    private func fetchSettingsFromAPI() async throws -> Data {

        let response: WordPressAPIResult<Data, WordPressOrgRestApiError> = await dotOrgRestAPI.get(
            path: "/wp-block-editor/v1/settings"
        )

        let data = try response.get() // Unwrap the result type

        let blogID = TaggedManagedObjectID(blog)
        saveSettingsInBackground(data, for: blogID)

        return data
    }

    /// Returns cached settings if available. If not, fetches the settings from
    /// the network.
    @MainActor
    func getSettings() async throws -> Data {
        // Return cached settings if available
        let blogID = TaggedManagedObjectID(blog)
        if let cachedSettings = await loadSettingsInBackground(for: blogID) {
            return cachedSettings
        }
        return try await fetchSettings()
    }

    @MainActor
    func getSettingsString() async throws -> String {
        let data = try await getSettings()
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string
    }
}

private func saveSettingsInBackground(_ settings: Data, for blogID: TaggedManagedObjectID<Blog>) {
    Task {
        do {
            try BlockEditorCache.shared.saveBlockSettings(settings, for: blogID)
        } catch {
            wpAssertionFailure("Unable to save block settings", userInfo: ["error": error])
        }
    }
}

private func loadSettingsInBackground(for blogID: TaggedManagedObjectID<Blog>) async -> Data? {
    BlockEditorCache.shared.getBlockSettings(for: blogID)
}
