import Foundation
import SwiftUI

/// Displays upload progress for the media for the given post.
struct PostMediaUploadStatusView: View {
    @ObservedObject var viewModel: PostMediaUploadViewModel

    var body: some View {
        contents
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: viewModel.buttonRetryTapped) {
                            Label(Strings.retryUploads, systemImage: "arrow.clockwise")
                        }.disabled(viewModel.isButtonRetryDisabled)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var contents: some View {
        if viewModel.uploads.isEmpty {
            Text(Strings.empty)
                .foregroundStyle(.secondary)
        } else {
            List {
                ForEach(viewModel.uploads) {
                    MediaUploadStatusView(viewModel: $0)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct MediaUploadStatusView: View {
    @ObservedObject var viewModel: MediaUploadViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            MediaThubmnailImageView(image: viewModel.thumbnail)
                .aspectRatio(viewModel.thumbnailAspectRatio, contentMode: .fit)
                .frame(maxHeight: viewModel.thumbnailMaxHeight)
                .clipped()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(viewModel.details)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            switch viewModel.state {
            case .uploading:
                MediaUploadProgressView(progress: viewModel.fractionCompleted)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            case .uploaded:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.secondary.opacity(0.33))
            }
        }
        .task {
            await viewModel.loadThumbnail()
        }
    }
}

struct MediaUploadProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.25),
                    lineWidth: 3
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(uiColor: .brand), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
        .frame(width: 16, height: 16)
    }
}

private struct MediaThubmnailImageView: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .cornerRadius(6)
            } else {
                Color(uiColor: .secondarySystemBackground)
                    .cornerRadius(6)
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("postMediaUploadStatusView.title", value: "Media Uploads", comment: "Title for post media upload status view")
    static let empty = NSLocalizedString("postMediaUploadStatusView.noPendingUploads", value: "No pending uploads", comment: "Placeholder text in postMediaUploadStatusView when no uploads remain")
    static let close = NSLocalizedString("postMediaUploadStatusView.close", value: "Close", comment: "Close button in postMediaUploadStatusView")
    static let retryUploads = NSLocalizedString("postMediaUploadStatusView.retryUploads", value: "Retry Uploads", comment: "Retry upload button in postMediaUploadStatusView")
}
