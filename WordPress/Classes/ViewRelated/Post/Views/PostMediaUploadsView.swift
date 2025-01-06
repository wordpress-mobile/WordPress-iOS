import Foundation
import SwiftUI

final class PostMediaUploadsViewController: UIHostingController<PostMediaUploadsView> {
    private let viewModel: PostMediaUploadsViewModel

    init(post: AbstractPost) {
        self.viewModel = PostMediaUploadsViewModel(post: post) // Manange lifecycle
        super.init(rootView: PostMediaUploadsView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Displays upload progress for the media for the given post.
struct PostMediaUploadsView: View {
    @ObservedObject var viewModel: PostMediaUploadsViewModel

    var body: some View {
        contents
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: viewModel.buttonRetryTapped) {
                            Label(Strings.retryUploads, systemImage: "arrow.clockwise")
                        }
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
                    PostMediaUploadItemView(viewModel: $0)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct PostMediaUploadItemView: View {
    @ObservedObject var viewModel: PostMediaUploadItemViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            MediaThubmnailImageView(image: viewModel.thumbnail)
                .aspectRatio(viewModel.thumbnailAspectRatio, contentMode: .fit)
                .frame(maxHeight: viewModel.thumbnailMaxHeight)
                .clipped()
                .frame(width: 40, height: 40)
                .padding(.trailing, 16)

            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(viewModel.details)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 8) {
                switch viewModel.state {
                case .uploading:
                    MediaUploadProgressView(progress: viewModel.fractionCompleted)
                        .padding(.trailing, 4) // To align with the exlamation mark
                    menu
                case .failed:
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    menu
                case .uploaded:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary.opacity(0.33))
                }
            }
        }
        .contextMenu {
            menuItems
        } preview: {
            SiteMediaPreviewView(media: viewModel.media)
        }
        .task {
            await viewModel.loadThumbnail()
        }
    }

    private var menu: some View {
        Menu {
            menuItems
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline)
                .tint(.secondary)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        if viewModel.error != nil {
            Button(action: viewModel.buttonRetryTapped) {
                Label(Strings.retryUpload, systemImage: "arrow.clockwise")
            }
        }
        Button(role: .destructive, action: viewModel.buttonCancelTapped) {
            Label(Strings.cancelUpload, systemImage: "trash")
        }
    }
}

struct MediaUploadProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(uiColor: UIAppColor.primary), style: StrokeStyle(lineWidth: 2, lineCap: .round))
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
    static let retryUpload = NSLocalizedString("postMediaUploadStatusView.retryUpload", value: "Retry Upload", comment: "Retry (single) upload button in postMediaUploadStatusView")
    static let cancelUpload = NSLocalizedString("postMediaUploadStatusView.cancelUpload", value: "Cancel Upload", comment: "Cancel (single) upload button in postMediaUploadStatusView")
    static let retryUploads = NSLocalizedString("postMediaUploadStatusView.retryUploads", value: "Retry Uploads", comment: "Retry upload button in postMediaUploadStatusView")
}
