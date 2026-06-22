import SwiftUI
import AsyncImageKit

struct MediaGridCell: View {
    let item: MediaGridItem
    let isAspectRatioMode: Bool

    var body: some View {
        // GeometryReader inside .aspectRatio(1, .fit) gives the cell a
        // square frame and a known size. Without this, `.resizable()` +
        // `.aspectRatio(.fit)` on the image renders at the image's
        // intrinsic pixel-derived size and overflows the cell horizontally
        // into adjacent grid positions.
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack(alignment: .bottomTrailing) {
                Color(uiColor: .secondarySystemBackground)
                content
                    .frame(width: side, height: side)
                    .clipped()
                durationOverlay
                stateOverlay
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: isAspectRatioMode ? 4 : 0))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
    }

    @ViewBuilder private var content: some View {
        switch item.kind {
        case .image:
            imageContent
        case .video:
            videoContent
        case .audio:
            kindIcon(systemImage: "waveform", title: item.displayTitle)
        case .document:
            kindIcon(systemImage: "doc", title: item.displayTitle)
        case .none:
            // Unknown kind (loading or failed-no-data): render the same grey
            // square the placeholder produced before; the state overlay draws
            // the spinner/error on top.
            Color(uiColor: .secondarySystemBackground)
        }
    }

    /// Video thumbnail via AsyncImageKit's `CachedAsyncImage(videoUrl:)`,
    /// which extracts a frame from the video file at `thumbnailURL` (the
    /// video's `sourceUrl`). The duration badge sits on top via the
    /// `durationOverlay` modifier. Falls back to a centered play-rectangle
    /// icon when the URL is missing.
    @ViewBuilder private var videoContent: some View {
        if let url = item.thumbnailURL {
            CachedAsyncImage(videoUrl: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "play.rectangle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .clipped()
        } else {
            Image(systemName: "play.rectangle.fill")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }

    /// Aspect-ratio mode letterboxes the image inside the square cell using
    /// `.fit` on the resizable image — this keeps the rendered image
    /// constrained to cell bounds and avoids the overflow that an outer
    /// `.aspectRatio(ratio, .fit)` modifier on the CachedAsyncImage wrapper
    /// produced (image escaping its cell horizontally into adjacent
    /// positions). Default mode uses `.fill` so the image crops to cover
    /// the cell. The whole cell rounds at 4pt in aspect-ratio mode (see
    /// outer `.clipShape` in `body`); this is a small deviation from V1
    /// which rounds only the inner image container, but the alternative
    /// caused a much worse rendering bug. See `SiteMediaCollectionCell` for
    /// the V1 reference.
    @ViewBuilder private var imageContent: some View {
        if isAspectRatioMode {
            CachedAsyncImage(url: item.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color(uiColor: .secondarySystemBackground)
            }
        } else {
            CachedAsyncImage(url: item.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(uiColor: .secondarySystemBackground)
            }
            .clipped()
        }
    }

    @ViewBuilder private var durationOverlay: some View {
        if let duration = item.durationString {
            Text(duration)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 0)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
        }
    }

    @ViewBuilder private var stateOverlay: some View {
        switch item.state {
        case .loading, .loaded(isUpToDate: false):
            Color.black.opacity(0.05)
        case .error:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
        case .loaded(isUpToDate: true):
            EmptyView()
        }
    }

    private func kindIcon(systemImage: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.title2)
            Text(title)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
                .padding(.horizontal, 4)
        }
        .foregroundStyle(.secondary)
    }
}
