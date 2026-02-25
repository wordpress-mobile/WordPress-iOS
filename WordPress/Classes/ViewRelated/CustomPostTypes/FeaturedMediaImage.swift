import SwiftUI
import AsyncImageKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Resolves a featured media ID to an image URL via the WordPress media REST
/// API, then displays it with `CachedAsyncImage`.
struct FeaturedMediaImage: View {
    let mediaId: MediaId
    let client: WordPressClient
    let mediaHost: MediaHost?

    @State private var imageURL: URL?

    var body: some View {
        if mediaId > 0 {
            CachedAsyncImage(url: imageURL, host: mediaHost) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.tertiarySystemFill)
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: mediaId) {
                await resolveImageURL()
            }
        }
    }

    private func resolveImageURL() async {
        do {
            let response = try await client.api.media.retrieveWithViewContext(mediaId: mediaId)
            imageURL = URL(string: response.data.sourceUrl)
        } catch {
            DDLogError("Failed to resolve featured media \(mediaId): \(error)")
        }
    }
}
