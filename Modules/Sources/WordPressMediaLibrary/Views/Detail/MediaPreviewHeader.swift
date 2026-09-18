import SwiftUI
import AsyncImageKit

struct MediaPreviewHeader: View {
    let display: MediaDetailDisplayModel

    var body: some View {
        ZStack {
            switch display.kind {
            case .image:
                CachedAsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .empty: ProgressView()
                    case .failure: typeIcon
                    @unknown default: typeIcon
                    }
                }
            case .video:
                if let url = URL(string: display.sourceUrl) {
                    CachedAsyncImage(videoUrl: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        typeIcon
                    }
                } else {
                    typeIcon
                }
            case .audio, .document:
                typeIcon
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 320)
        .background(Color(.secondarySystemBackground))
        .accessibilityLabel(accessibilityLabel)
    }

    private var thumbnailURL: URL? {
        guard
            let payload = display.mediaDetails.parseAsMimeType(mimeType: display.mimeType),
            case .image(let imageDetails) = payload
        else { return URL(string: display.sourceUrl) }
        return MediaThumbnailURL.pick(from: imageDetails, sourceUrl: display.sourceUrl)
    }

    private var typeIcon: some View {
        Image(systemName: display.kind.systemImageName)
            .font(.system(size: 64))
            .foregroundStyle(.secondary)
    }

    private var accessibilityLabel: String {
        switch display.kind {
        case .image: return Strings.detailPreviewImageAccessibility
        case .video: return Strings.detailPreviewVideoAccessibility
        case .audio: return Strings.detailPreviewAudioAccessibility
        case .document: return Strings.detailPreviewDocumentAccessibility
        }
    }
}
