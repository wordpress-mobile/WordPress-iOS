import SwiftUI
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        switch viewModel.state {
        case .empty:
            MediaPicker(filter: .images, onSelection: viewModel.setFeaturedImage) {
                Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // Make the whole cell tappable
            }
        case .uploading(let viewModel):
            PostSettingsFeaturedImageUploadView(viewModel: viewModel, onCancelTapped: {
                self.viewModel.didCancelUpload()
                viewModel.buttonCancelTapped()
            })
        }
    }
}

private struct PostSettingsFeaturedImageUploadView: View {
    @ObservedObject var viewModel: MediaUploadItemViewModel

    var onCancelTapped: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ProgressView()
                .padding(.trailing, 12)

            VStack(alignment: .leading) {
                Text(Strings.uploading)
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
                    EmptyView() // processing
                }
            }
        }
    }

    private var menu: some View {
        Menu {
            if viewModel.error != nil {
                Button(action: viewModel.buttonRetryTapped) {
                    Label(Strings.retryUpload, systemImage: "arrow.clockwise")
                }
            }
            Button(role: .destructive, action: onCancelTapped) {
                Label(Strings.cancelUpload, systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline)
                .tint(.secondary)
        }
    }
}

final class PostSettingsFeaturedImageViewModel: NSObject, ObservableObject {
    @Published private(set) var state: State = .empty

    let post: AbstractPost

    private let coordinator = MediaCoordinator.shared

    @objc init(post: AbstractPost) {
        self.post = post
    }

    enum State {
        case empty
        case uploading(MediaUploadItemViewModel)
    }

    func setFeaturedImage(from items: [MediaPickerSelection]) {
        guard let item = items.first else {
            return wpAssertionFailure("selection is empty")
        }
        guard let media = coordinator.addMedia(from: item.exportableAsset, to: post) else {
            return wpAssertionFailure("failed to add media to post")
        }
        let viewModel = MediaUploadItemViewModel(media: media, coordinator: coordinator)
        self.state = .uploading(viewModel)
    }

    func didCancelUpload() {
        // TODO: restore to the previous state
        state = .empty
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
    static let uploading = NSLocalizedString("postSettings.featuredImage.uploading", value: "Uploading…", comment: "Post Settings")
    static let retryUpload = NSLocalizedString("postSettings.featuredImage.retryUpload", value: "Retry Upload", comment: "Retry (single) upload button in Post Settings / Featuerd Image cell")
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel (single) upload button in Post Settings / Featuerd Image cell")
}
