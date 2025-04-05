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
    func fetchSettings() async throws -> [String: Any] {
        // Start a background refresh if needed
        if !isRefreshing && (blog.rawBlockEditorSettingsLastFetchTime == nil || Date().timeIntervalSince(blog.rawBlockEditorSettingsLastFetchTime!) >= 0) {
            isRefreshing = true
            Task {
                do {
                    let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
                    switch result {
                    case .success(let response):
                        if let dictionary = response as? [String: Any] {
                            blog.rawBlockEditorSettings = dictionary
                            blog.rawBlockEditorSettingsLastFetchTime = Date()
                        }
                    case .failure(let error):
                        DDLogError("Error refreshing block editor settings: \(error)")
                    }
                    isRefreshing = false
                }
            }
        }

        // Return cached settings if available, otherwise fetch fresh
        if let cachedSettings = blog.rawBlockEditorSettings {
            return cachedSettings
        }

        // If no cache, fetch synchronously
        let result = await self.remoteAPI.get(path: "/wp-block-editor/v1/settings")
        switch result {
        case .success(let response):
            guard let dictionary = response as? [String: Any] else {
                throw NSError(domain: "RawBlockEditorSettingsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            blog.rawBlockEditorSettings = dictionary
            blog.rawBlockEditorSettingsLastFetchTime = Date()
            return dictionary
        case .failure(let error):
            throw error
        }
    }
}
