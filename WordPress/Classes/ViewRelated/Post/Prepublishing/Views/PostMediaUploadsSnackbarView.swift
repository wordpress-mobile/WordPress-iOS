import SwiftUI

struct PostMediaUploadsSnackbarView: View {
    let state: PostMediaUploadsSnackbarState

    private let accessoryViewWidth: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            switch state {
            case let .uploading(title, details, progress):
                if let progress {
                    MediaUploadProgressView(progress: progress)
                        .frame(width: accessoryViewWidth)
                } else {
                    ProgressView()
                        .foregroundStyle(.secondary)
                        .frame(width: accessoryViewWidth)
                }
                makeDetailsView(title: title, details: details)
            case let .failed(title, details):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.red)
                    .frame(width: accessoryViewWidth)
                makeDetailsView(title: title, details: details)
            }
        }
    }

    private func makeDetailsView(title: String, details: String?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            if let details {
                Text(details)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .lineLimit(1)
    }
}

enum PostMediaUploadsSnackbarState {
    case uploading(title: String, details: String, progress: Double?)
    case failed(title: String, details: String? = nil)
}

#Preview {
    VStack(spacing: 16) {
        PostMediaUploadsSnackbarView(state: .uploading(title: "Uploading media...", details: "2 items remaining", progress: 0.2))
        PostMediaUploadsSnackbarView(state: .failed(title: "Failed to upload media"))
        PostMediaUploadsSnackbarView(state: .failed(title: "Failed to upload media", details: "Not connected to Internet"))
    }
    .padding()
}
