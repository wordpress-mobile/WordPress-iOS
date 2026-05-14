import SwiftUI
import AsyncImageKit

struct MediaGridCell: View {
    let item: MediaGridItem
    let isAspectRatioMode: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(uiColor: .secondarySystemBackground)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            durationOverlay
            stateOverlay
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
            Image(systemName: "play.rectangle.fill")
                .font(.title)
                .foregroundStyle(.secondary)
        case .audio:
            kindIcon(systemImage: "waveform", title: item.displayTitle)
        case .document:
            kindIcon(systemImage: "doc", title: item.displayTitle)
        }
    }

    /// V1 parity for aspect-ratio mode: the inner image container takes the
    /// media's natural aspect ratio centered inside the square cell. In
    /// default mode the container fills the cell and the image crops. See
    /// `SiteMediaCollectionCell.swift:113-125` for the V1 reference.
    @ViewBuilder private var imageContent: some View {
        let cached = CachedAsyncImage(url: item.thumbnailURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color(uiColor: .secondarySystemBackground)
        }
        if isAspectRatioMode, let ratio = item.aspectRatio {
            cached
                .aspectRatio(ratio, contentMode: .fit)
                .clipped()
        } else {
            cached.clipped()
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
