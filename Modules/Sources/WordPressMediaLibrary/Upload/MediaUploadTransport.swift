import Foundation
import WordPressAPI
import WordPressCore

/// Module-internal seam over the wp_mobile-side upload call.
protocol MediaUploadTransport: Sendable {
    func upload(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaWithEditContext
}

struct DefaultMediaUploadTransport: MediaUploadTransport {
    let client: WordPressClient

    init(client: WordPressClient) {
        self.client = client
    }

    func upload(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaWithEditContext {
        let service = try await client.service
        return try await service.uploadMedia(params: params, fulfilling: progress)
    }
}
