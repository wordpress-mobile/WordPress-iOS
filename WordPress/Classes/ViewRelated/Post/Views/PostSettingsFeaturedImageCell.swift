import SwiftUI
import AsyncImageKit
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var post: AbstractPost
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        if let image = post.featuredImage {
            SiteMediaImage(media: image, size: .large)
                .loadingStyle(.spinner)
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
            let configuration = MediaPickerConfiguration(
                sources: [.photos, .camera, .playground, .siteMedia(blog: post.blog)],
                filter: .images
            )
            MediaPicker(configuration: configuration, onSelection: viewModel.setFeaturedImage) {
                Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // Make the whole cell tappable
                    .accessibilityIdentifier("SetFeaturedImage")
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

final class PostSettingsFeaturedImageViewModel: NSObject, ObservableObject {
    @Published private(set) var upload: Media?

    let post: AbstractPost

    private var receipt: UUID?
    private let coordinator = MediaCoordinator.shared

    @objc weak var tableView: UITableView?
    @objc weak var delegate: FeaturedImageDelegate?

    @objc init(post: AbstractPost) {
        self.post = post
    }

    func setFeaturedImage(selection: MediaPickerSelection) {
        WPAnalytics.track(.editorPostFeaturedImageChanged, properties: ["via": "settings", "action": "added", "source": selection.source])

        guard let item = selection.items.first else {
            return wpAssertionFailure("selection is empty")
        }
        switch item.exported() {
        case .asset(let exportableAsset):
            guard let media = coordinator.addMedia(from: exportableAsset, to: post) else {
                return wpAssertionFailure("failed to add media to post")
            }
            self.receipt = coordinator.addObserver({ [weak self] media, state in
                self?.didUpdateUploadState(state, media: media)
            }, for: media)
            self.upload = media
        case .media(let media):
            didProcessMedia(media)
        }
    }

    private func didUpdateUploadState(_ state: MediaCoordinator.MediaState, media: Media) {
        switch state {
        case .ended:
            didProcessMedia(media)
        case .failed(let error):
            Notice(title: Strings.uploadFailed, message: error.localizedDescription).post()
            upload = nil
        default:
            break
        }
    }

    private func didProcessMedia(_ media: Media) {
        wpAssert(media.remoteURL != nil)

        upload = nil
        setFeaturedImage(media)
    }
    func buttonCancelTapped() {
        guard let upload else { return }
        coordinator.cancelUploadAndDeleteMedia(upload)
        self.upload = nil
    }

    func buttonRemoveTapped() {
        WPAnalytics.track(.editorPostFeaturedImageChanged, properties: ["via": "settings", "action": "removed"])

        setFeaturedImage(nil)
    }

    private func setFeaturedImage(_ media: Media?) {
        upload = nil
        post.featuredImage = media
        delegate?.gutenbergDidRequestFeaturedImageId(media?.mediaID ?? GutenbergFeaturedImageHelper.mediaIdNoFeaturedImageSet as NSNumber)
        UIView.performWithoutAnimation {
            tableView?.reloadData()
        }
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.featuredImage.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
    static let uploading = NSLocalizedString("postSettings.featuredImage.uploading", value: "Uploading…", comment: "Post Settings")
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel (single) upload button in Post Settings / Featuerd Image cell")
    static let uploadFailed = NSLocalizedString("postSettings.featuredImage.uploadFailed", value: "Failed to upload new featured image", comment: "Snackbar title")
}
