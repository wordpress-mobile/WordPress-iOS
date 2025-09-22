import SwiftUI
import AsyncImageKit
import WordPressData
import WordPressUI
import UIKit

struct PostSettingsFeaturedImageRow: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel
    @State private var presentedMedia: Media?

    @ScaledMetric(relativeTo: .body) var height = 110

    var body: some View {
        Group {
            if let image = viewModel.selection {
                makeMediaView(with: image)
            } else {
                Group {
                    if viewModel.upload != nil {
                        // The upload state when no image is selected. For the "Replace"
                        // flow, the app shows the upload differently (see `menu`).
                        uploadingStateView
                    } else {
                        makeMediaPicker {
                            setFeaturedImageView
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .frame(height: height)
            }
        }
        .listRowInsets(EdgeInsets.zero)
    }

    private func makeMediaView(with image: Media) -> some View {
        SiteMediaImage(media: image, size: .large)
            .loadingStyle(.spinner)
            // warning: SiteMediaImage doesn't seem to reload otherwise; might want to change it later
            .id(image)
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
    }

    private var setFeaturedImageView: some View {
        makeWithProminentBackground {
            VStack(spacing: 4) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)

                Text(Strings.buttonSetFeaturedImage)
                    .font(.body)
            }
            .foregroundColor(.accentColor)
            .fontWeight(.medium)
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
                        .accessibilityIdentifier("featured_image_current_image_menu") // not ideal
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

    private var uploadingStateView: some View {
        Menu {
            Button(role: .destructive, action: viewModel.buttonCancelTapped) {
                Label(Strings.cancelUpload, systemImage: "xmark.circle.fill")
            }
        } label: {
            makeWithProminentBackground {
                HStack {
                    ProgressView()

                    Text(Strings.uploading)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.secondary)
                    .padding(12)
            }
        }
    }

    /// A nice tinted background for the button and other states.
    private func makeWithProminentBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ZStack {
            // System background that adapts to dark mode
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.secondarySystemGroupedBackground))

            content()

            // Prominent border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        }
    }

    private var cornerRadius: CGFloat {
        if #available(iOS 26, *) { 26 } else { 12 }
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
    static let cancelUpload = NSLocalizedString("postSettings.featuredImage.cancelUpload", value: "Cancel Upload", comment: "Cancel upload button in Post Settings / Featured Image cell")
    static let replaceImage = NSLocalizedString("postSettings.featuredImage.replaceImage", value: "Replace", comment: "Replace image upload button in Post Settings / Featured Image cell")
    static let uploadFailed = NSLocalizedString("postSettings.featuredImage.uploadFailed", value: "Failed to upload new featured image", comment: "Snackbar title")
}
