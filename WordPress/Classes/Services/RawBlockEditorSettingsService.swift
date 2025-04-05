import Foundation
import WordPressKit
import WordPressShared

class RawBlockEditorSettingsService {
    private let blog: Blog
    private let remoteAPI: WordPressOrgRestApi
    private var isRefreshing: Bool = false

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
            blog.rawBlockEditorSettings = dictionary
            return dictionary
        case .failure(let error):
            throw error
        }
    }

    @MainActor
    func fetchSettings() async throws -> [String: Any] {
        // Start a background refresh if not already refreshing
        if !isRefreshing {
            isRefreshing = true
            Task {
                do {
                    _ = try await fetchSettingsFromAPI()
                } catch {
                    DDLogError("Error refreshing block editor settings: \(error)")
                }
                isRefreshing = false
            }
        }

        // Return cached settings if available
        if let cachedSettings = blog.rawBlockEditorSettings {
            return cachedSettings
        }

        // If no cache and no background refresh in progress, fetch synchronously
        if !isRefreshing {
            return try await fetchSettingsFromAPI()
        }

        // If we're here, it means a background refresh is in progress
        // Wait for it to complete and return the cached result
        while isRefreshing {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            if let cachedSettings = blog.rawBlockEditorSettings {
                return cachedSettings
            }
        }

        // If we still don't have settings after the refresh completed, throw an error
        throw NSError(domain: "RawBlockEditorSettingsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch block editor settings"])
    }
}
