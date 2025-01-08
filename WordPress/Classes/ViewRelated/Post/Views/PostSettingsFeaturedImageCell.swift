import SwiftUI
import AsyncImageKit
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var post: AbstractPost
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        if let imageURL = viewModel.featuredImageURL {
            FeaturedImageView(imageURL: imageURL, post: viewModel.post)
                .aspectRatio(1.0 / ReaderPostCell.coverAspectRatio, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Menu {
                        Button(SharedStrings.Button.remove, systemImage: "trash", role: .destructive, action: viewModel.buttonRemoveTapped)
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(Color(.label), Color(.secondarySystemBackground))
                            .font(.title)
                            .padding(8)
                    }
                }
        } else if viewModel.upload != nil {
            uploading
        } else {
            MediaPicker(filter: .images, onSelection: viewModel.setFeaturedImage) {
                Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // Make the whole cell tappable
            }
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
                Button(role: .destructive, action: viewModel.buttonCancelTapped) {
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

private struct FeaturedImageView: UIViewRepresentable {
    let imageURL: URL
    let post: AbstractPost

    func makeUIView(context: Context) -> AsyncImageView {
        let imageView = AsyncImageView()
        imageView.configuration.loadingStyle = .spinner
        imageView.setImage(with: imageURL, host: MediaHost(post))
        return imageView
    }

    func updateUIView(_ view: AsyncImageView, context: Context) {
        // Do nothing
    }
}

final class PostSettingsFeaturedImageViewModel: NSObject, ObservableObject {
    @Published private(set) var upload: Media?

    let post: AbstractPost

    var featuredImageURL: URL? {
        post.featuredImage?.remoteURL.flatMap(URL.init)
    }

    private var receipt: UUID?
    private let coordinator = MediaCoordinator.shared

    @objc weak var tableView: UITableView?

    @objc init(post: AbstractPost) {
        self.post = post
    }

    func setFeaturedImage(from items: [MediaPickerSelection]) {
        guard let item = items.first else {
            return wpAssertionFailure("selection is empty")
        }
        guard let media = coordinator.addMedia(from: item.exportableAsset, to: post) else {
            return wpAssertionFailure("failed to add media to post")
        }
        self.receipt = coordinator.addObserver({ [weak self] media, state in
            self?.didUpdateUploadState(state, media: media)
        }, for: media)
        self.upload = media
    }

    private func didUpdateUploadState(_ state: MediaCoordinator.MediaState, media: Media) {
        switch state {
        case .ended:
            wpAssert(media.remoteURL != nil)
            UIView.performWithoutAnimation {
                post.featuredImage = media
                tableView?.reloadData()
            }
        case .failed(let error):
            Notice(title: Strings.uploadFailed, message: error.localizedDescription).post()
            upload = nil
        default:
            break
        }
    }

    func buttonCancelTapped() {
        guard let upload else { return }
        coordinator.cancelUploadAndDeleteMedia(upload)
        self.upload = nil
    }

    func buttonRemoveTapped() {
        WPAnalytics.track(.editorPostFeaturedImageChanged, properties: [
            "via": "settings", "action": "removed"
        ])

        post.featuredImage = nil
        tableView?.reloadData()
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
    static let uploading = NSLocalizedString("postSettings.featuredImage.uploading", value: "Uploading…", comment: "Post Settings")
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel (single) upload button in Post Settings / Featuerd Image cell")
    static let uploadFailed = NSLocalizedString("postSettings.featuredImage.uploadFailed", value: "Failed to upload new featured image", comment: "Snackbar title")
}
