import Foundation
import WordPressKit
import WordPressShared

class RawBlockEditorSettingsService {
    private let blog: Blog
    private let remoteAPI: WordPressOrgRestApi

    // Cache for the settings
    private var cachedSettings: [String: Any]?
    private var lastFetchTime: Date?

    init?(blog: Blog) {
        guard let remoteAPI = WordPressOrgRestApi(blog: blog) else {
            return nil
        }

        self.blog = blog
        self.remoteAPI = remoteAPI
    }

    @MainActor
    func fetchSettings() async throws -> [String: Any] {
        // If we have cached settings and they're less than 5 minutes old, return them
        if let cachedSettings = cachedSettings,
           let lastFetchTime = lastFetchTime,
           Date().timeIntervalSince(lastFetchTime) < 300 { // 5 minutes
            return cachedSettings
        }

        let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
        switch result {
        case .success(let response):
            guard let dictionary = response as? [String: Any] else {
                throw NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            // Cache the successful response
            cachedSettings = dictionary
            lastFetchTime = Date()
            return dictionary
        case .failure(let error):
            throw error
        }
    }
}
