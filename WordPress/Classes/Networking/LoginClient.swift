import Foundation
import WordPressAPI
import AutomatticTracks

actor LoginClient {
    
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func performLoginAutodiscovery(for url: URL) async throws {
        let internalClient = WordPressLoginClient(urlSession: self.session)

        do {
            _ = try await internalClient.discoverLoginUrl(for: url.absoluteString)
            // TODO: Make this do something useful later
        } catch {
            await WordPressAppDelegate.crashLogging?.logError(error)
            throw error
        }
    }

    private func trackError(_ error: Error, url: URL) {
        WPAnalytics.track(.unableToPerformURLAutodiscovery, properties: [
            "url": url
        ])
    }
}
