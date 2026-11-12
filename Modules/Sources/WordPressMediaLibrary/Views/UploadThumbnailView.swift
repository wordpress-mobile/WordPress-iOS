import QuickLookThumbnailing
import SwiftUI

/// QuickLook thumbnail for a local upload file. Falls back to the kind's
/// SF Symbol until generation finishes, or permanently when QuickLook
/// cannot preview the type (e.g. audio). Requesting only `.thumbnail`
/// (never `.icon`) keeps that failure clean instead of yielding a generic
/// system file icon. No caching: scroll-back regenerates, which is cheap
/// for local files.
struct UploadThumbnailView: View {
    let fileURL: URL
    let fallbackSystemImage: String

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: fallbackSystemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: fileURL) {
            let request = QLThumbnailGenerator.Request(
                fileAt: fileURL,
                size: CGSize(width: 44, height: 44),
                scale: displayScale,
                representationTypes: .thumbnail
            )
            // Extract UIImage inside the completion handler so that only the
            // Sendable UIImage crosses the concurrency boundary, not the
            // non-Sendable QLThumbnailRepresentation.
            let image: UIImage? = await withCheckedContinuation { continuation in
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                    continuation.resume(returning: representation?.uiImage)
                }
            }
            thumbnail = image
        }
    }
}
