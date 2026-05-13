import SwiftUI
import AsyncImageKit

struct MediaLibraryRow: View {
    let item: MediaListItem

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(displayTitle)
                .font(.body)
                .lineLimit(1)
            Spacer()
        }
        .opacity(opacityForState)
        .accessibilityLabel(displayTitle)
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch item.state {
        case .error:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
        case .loading, .loaded:
            // Use the closure-form initializer so we can call
            // `.resizable()` on the inner image — the default
            // `CachedAsyncImage(url:)` returns a non-resizable Image (or a
            // Color), which would render at the asset's natural size and
            // ignore the .frame(width: 44, height: 44) we apply outside.
            // Matches the existing pattern in JetpackStats/Views/AvatarView.swift.
            CachedAsyncImage(url: item.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(uiColor: .secondarySystemBackground)
            }
        }
    }

    private var displayTitle: String {
        item.title ?? Strings.untitled
    }

    private var opacityForState: Double {
        if case .loaded(let isUpToDate) = item.state, !isUpToDate {
            return 0.7
        }
        return 1.0
    }
}
