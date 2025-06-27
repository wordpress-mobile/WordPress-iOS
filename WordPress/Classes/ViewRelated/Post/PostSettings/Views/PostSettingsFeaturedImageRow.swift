import SwiftUI
import AsyncImageKit
import WordPressData
import WordPressUI
import UIKit

struct PostSettingsFeaturedImageRow: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel
    @State private var presentedMedia: Media?

    @ScaledMetric(relativeTo: .body) var height = 108 // Matches "Exceprt"

    var body: some View {
        if let image = viewModel.selection {
            SiteMediaImage(media: image, size: .large)
                .loadingStyle(.spinner)
                // warning: SiteMediaImage doesn't seem to reload otherwise; might want to change it later
                .id(image)
                .accessibilityIdentifier("featured_image_current_image")
                .aspectRatio(1.0 / ReaderPostCell.coverAspectRatio, contentMode: .fit)
                .overlay {
                    menu
                }
                .contextMenu {
                    actions
                }
                .sheet(item: $presentedMedia) { media in
                    LightboxView(media: media)
                        .ignoresSafeArea()
                }
                .listRowInsets(EdgeInsets.zero)
        } else {
            Group {
                if viewModel.upload != nil {
                    // The upload state when no image is selected. For the "Replace"
                    // flow, the app shows the upload differently (see `menu`).
                    uploading
                        .padding(.vertical, 12)
                } else {
                    makeMediaPicker {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                            Text(Strings.buttonSetFeaturedImage)
                                .font(.callout.weight(.medium))
                        }
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle()) // Make the whole cell tappable
                    }
                }
            }
            .frame(height: height)
            .listRowInsets(EdgeInsets(top: 1, leading: 16, bottom: 1, trailing: 16))
        }
    }

    private var menu: some View {
        Menu {
            actions
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color(.secondarySystemBackground))
                    .frame(width: 30, height: 30)
                if viewModel.upload != nil {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color(.label))
                        .font(.system(size: 18))
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 10)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if viewModel.upload == nil {
            Button(SharedStrings.Button.view, systemImage: "plus.magnifyingglass") {
                presentedMedia = viewModel.selection
            }
            .accessibilityIdentifier("featured_image_button_view")
            makeMediaPicker {
                Button(Strings.replaceImage, systemImage: "photo.badge.plus", action: {})
                    .accessibilityIdentifier("featured_image_button_replace")
            }
            Button(SharedStrings.Button.remove, systemImage: "trash", role: .destructive, action: viewModel.buttonRemoveTapped)
                .accessibilityIdentifier("featured_image_button_remove")
        } else {
            Button(role: .destructive, action: viewModel.buttonCancelTapped) {
                Label(Strings.cancelUpload, systemImage: "trash")
            }
        }
    }

    private var uploading: some View {
        HStack(alignment: .center, spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.uploading)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(Strings.uploadingSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Menu {
                Button(role: .destructive, action: viewModel.buttonCancelTapped) {
                    Label(Strings.cancelUpload, systemImage: "xmark.circle.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .tint(.secondary)
            }
        }
    }

    private func makeMediaPicker<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        let configuration = MediaPickerConfiguration(
            sources: [.photos, .camera, .playground, .siteMedia(blog: viewModel.post.blog)],
            filter: .images
        )
        return MediaPicker(configuration: configuration, onSelection: viewModel.setFeaturedImage) {
            content()
        }
    }
}

public final class PostSettingsFeaturedImageViewModel: ObservableObject {
    @Published private(set) var upload: Media?
    @Published var selection: Media?

    let post: AbstractPost

    private var receipt: UUID?
    private let coordinator = MediaCoordinator.shared

    public init(post: AbstractPost) {
        self.post = post
        self.selection = post.featuredImage
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
        withAnimation {
            upload = nil
            selection = media
        }
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.featuredImage.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
    static let uploading = NSLocalizedString("postSettings.featuredImage.uploading", value: "Uploading…", comment: "Post Settings")
    static let uploadingSubtitle = NSLocalizedString("postSettings.featuredImage.uploadingSubtitle", value: "Please wait...", comment: "Subtitle shown while uploading featured image")
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel upload button in Post Settings / Featured Image cell")
    static let replaceImage = NSLocalizedString("postSettings.featuredImage.replaceImage", value: "Replace", comment: "Replace image upload button in Post Settings / Featured Image cell")
    static let uploadFailed = NSLocalizedString("postSettings.featuredImage.uploadFailed", value: "Failed to upload new featured image", comment: "Snackbar title")
}
