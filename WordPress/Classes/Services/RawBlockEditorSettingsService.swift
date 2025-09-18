import Foundation
import WordPressData
import WordPressKit
import WordPressShared

final class RawBlockEditorSettingsService {

    private let blogID: String
    private var refreshTask: Task<Data, Error>?
    private let dotOrgRestAPI: WordPressOrgRestApi
    private var prefetchTask: Task<Void, Never>?

    @MainActor
    init(blog: Blog) {
        self.dotOrgRestAPI = WordPressOrgRestApi(blog: blog)!
        self.blogID = blog.locallyUniqueId
    }

    private func fetchSettingsFromAPI() async throws -> Data {
        let response: WordPressAPIResult<Data, WordPressOrgRestApiError> = await dotOrgRestAPI.get(
            path: "/wp-block-editor/v1/settings"
        )

        let data = try response.get() // Unwrap the result type
        try await BlockEditorCache.shared.saveBlockSettings(data, for: blogID)

        return data
    }

    /// Returns cached settings if available. If not, fetches the settings from
    /// the network.
    func getSettings(allowingCachedResponse: Bool = true) async throws -> Data {
        // Return cached settings if available
        if allowingCachedResponse, let cachedSettings = try await BlockEditorCache.shared.getBlockSettings(for: blogID) {
            return cachedSettings
        }
        return try await fetchSettingsFromAPI()
    }

    func getSettingsString(allowingCachedResponse: Bool = true) async throws -> String {
        let data = try await getSettings(allowingCachedResponse: allowingCachedResponse)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string
    }

    func prefetchSettings() {
        guard self.prefetchTask == nil else { return }
        self.prefetchTask = Task {
            do {
                _ = try await fetchSettingsFromAPI()
            } catch {
                debugPrint("Failed to prefetch block editor settings: \(error)")
            }
        }
    }
}
