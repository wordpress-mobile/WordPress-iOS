import SwiftUI

struct UploadRow: View {
    let item: MediaLibraryViewModel.UploadRowItem
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.systemImageName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline)
                    .lineLimit(1)
                switch item.mode {
                case .uploading(let progress):
                    ProgressView(progress)
                        .progressViewStyle(.linear)
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
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.uploadActionDismiss)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
