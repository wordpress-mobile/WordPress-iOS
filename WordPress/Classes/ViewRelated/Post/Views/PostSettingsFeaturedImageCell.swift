import SwiftUI
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        switch viewModel.state {
        case .empty: empty
        case .uploading: uploading
        }
    }

    private var empty: some View {
        MediaPicker(filter: .images, onSelection: viewModel.setFeaturedImage) {
            Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // Make the whole cell tappable
        }
    }

    private var uploading: some View {
        HStack(alignment: .center, spacing: 0) {
            ProgressView()
                .padding(.trailing, 12)

            Text(Strings.uploading)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Menu {
                Button(role: .destructive, action: viewModel.onCancelTapped) {
                    Label(Strings.cancelUpload, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .tint(.secondary)
            }
        }
    }
}

final class PostSettingsFeaturedImageViewModel: NSObject, ObservableObject {
    @Published private(set) var state: State = .empty

    let post: AbstractPost

    private var receipt: UUID?
    private let coordinator = MediaCoordinator.shared

    @objc init(post: AbstractPost) {
        self.post = post
    }

    enum State {
        case empty
        case uploading(Media)
    }

    func setFeaturedImage(from items: [MediaPickerSelection]) {
        guard let item = items.first else {
            return wpAssertionFailure("selection is empty")
        }
        guard let media = coordinator.addMedia(from: item.exportableAsset, to: post) else {
            return wpAssertionFailure("failed to add media to post")
        }
        self.receipt = coordinator.addObserver({ [weak self] _, state in
            self?.didUpdateUploadState(state)
        }, for: media)
        self.state = .uploading(media)
    }

    private func didUpdateUploadState(_ state: MediaCoordinator.MediaState) {
        switch state {
        case .ended:
            // TODO: upload media
            break
        case .failed(let error):
            Notice(title: Strings.uploadFailed, message: error.localizedDescription).post()
            reset()
        default:
            break
        }
    }

    func onCancelTapped() {
        guard case .uploading(let media) = state else {
            return
        }
        coordinator.cancelUploadAndDeleteMedia(media)
        reset()
    }

    private func reset() {
        state = .empty // TODO: restore previous state
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
    static let uploading = NSLocalizedString("postSettings.featuredImage.uploading", value: "Uploading…", comment: "Post Settings")
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel (single) upload button in Post Settings / Featuerd Image cell")
    static let uploadFailed = NSLocalizedString("postSettings.featuredImage.uploadFailed", value: "Failed to upload new featured image", comment: "Snackbar title")
}
