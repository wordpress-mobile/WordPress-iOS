import Foundation
import WordPressKit
import WordPressShared

class RawBlockEditorSettingsService {
    private let blog: Blog
    private let remoteAPI: WordPressOrgRestApi

    // Cache for the settings
    private var cachedSettings: [String: Any]?
    private var lastFetchTime: Date?
    private var isRefreshing: Bool = false

    init?(blog: Blog) {
        guard let remoteAPI = WordPressOrgRestApi(blog: blog) else {
            return nil
        }

        self.blog = blog
        self.remoteAPI = remoteAPI
    }

    @MainActor
    func fetchSettings() async throws -> [String: Any] {
        // Start a background refresh if needed
        if !isRefreshing && (lastFetchTime == nil || Date().timeIntervalSince(lastFetchTime!) >= 300) {
            isRefreshing = true
            Task {
                do {
                    let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
                    switch result {
                    case .success(let response):
                        if let dictionary = response as? [String: Any] {
                            cachedSettings = dictionary
                            lastFetchTime = Date()
                        }
                    case .failure(let error):
                        DDLogError("Error refreshing block editor settings: \(error)")
                    }
                    isRefreshing = false
                }
            }
        }

        // Return cached settings if available, otherwise fetch fresh
        if let cachedSettings {
            return cachedSettings
        }

        // If no cache, fetch synchronously
        let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
        switch result {
        case .success(let response):
            guard let dictionary = response as? [String: Any] else {
                throw NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            cachedSettings = dictionary
            lastFetchTime = Date()
            return dictionary
        case .failure(let error):
            throw error
        }
    }
}
