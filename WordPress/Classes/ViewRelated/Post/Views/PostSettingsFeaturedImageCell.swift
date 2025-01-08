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
            PostMediaUploadItemView(viewModel: viewModel)
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
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
}
