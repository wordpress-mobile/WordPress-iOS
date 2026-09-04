import Combine
import SwiftUI

struct UploadRow: View {
    let item: MediaLibraryViewModel.UploadRowItem
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let fileURL = item.localFileURL {
                UploadThumbnailView(
                    fileURL: fileURL,
                    fallbackSystemImage: item.kind.systemImageName
                )
            } else {
                Image(systemName: item.kind.systemImageName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline)
                    .lineLimit(1)
                switch item.mode {
                case .uploading(let progress):
                    UploadProgressBar(progress: progress)
                case .failed(let message, _):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            switch item.mode {
            case .uploading:
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            case .failed(_, let isRetryable):
                HStack(spacing: 16) {
                    if isRetryable {
                        Button(action: onRetry) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Strings.uploadActionRetry)
                    }
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.uploadActionRemove)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// Bar-only progress. `ProgressView(_ progress:)` would auto-render two text
/// labels, including "N of 100" (the uploader's internal unit count), so this
/// observes `fractionCompleted` manually and feeds a label-free bar.
private struct UploadProgressBar: View {
    let progress: Progress
    @State private var fraction: Double

    init(progress: Progress) {
        self.progress = progress
        _fraction = State(initialValue: progress.fractionCompleted)
    }

    var body: some View {
        ProgressView(value: fraction)
            .progressViewStyle(.linear)
            .onReceive(
                progress.publisher(for: \.fractionCompleted)
                    .receive(on: DispatchQueue.main)
            ) { fraction = $0 }
    }
}
