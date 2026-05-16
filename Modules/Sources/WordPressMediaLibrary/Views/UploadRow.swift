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
                HStack {
                    if isRetryable {
                        Button(Strings.uploadActionRetry, action: onRetry)
                    }
                    Button(Strings.uploadActionDismiss, action: onDismiss)
                        .tint(.secondary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }
}
