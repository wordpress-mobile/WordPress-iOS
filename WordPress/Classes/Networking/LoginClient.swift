import Foundation
import WordPressAPI
import AutomatticTracks

actor LoginClient {
    
    struct ApiDetails {
        let rootUrl: ParsedUrl
        let loginUrl: String?
    }

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func performLoginAutodiscovery(for url: URL) async throws -> ApiDetails {
        try await performLoginAutodiscovery(for: url.absoluteString)
    }

    func performLoginAutodiscovery(for string: String) async throws -> ApiDetails {
        let internalClient = WordPressLoginClient(urlSession: self.session)

        do {
            let result = try await internalClient.discoverLoginUrl(for: string)
            trackSuccess(url: string)
            return ApiDetails(rootUrl: result.apiRootUrl, loginUrl: result.apiDetails.findApplicationPasswordsAuthenticationUrl())
        } catch {
            await WordPressAppDelegate.crashLogging?.logError(error)
            throw error
        }
    }

    private func trackSuccess(url: String) {
        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": true
        ])
    }

    private func trackError(_ error: Error, url: String) {
        WPAnalytics.track(.performedUrlDiscovery, properties: [
            "url": url,
            "success": false
        ])
    }
}
