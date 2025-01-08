import SwiftUI
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        MediaPicker(filter: .images, onSelection: viewModel.setFeaturedImage) {
            Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle()) // Make the whole cell tappable
        }
    }
}

final class PostSettingsFeaturedImageViewModel: NSObject, ObservableObject {
    @Published private var state: State = .empty

    let blog: Blog

    @objc init(blog: Blog) {
        self.blog = blog
    }

    enum State {
        case empty
        // TODO: show PostMediaUploadsView
        case uploading
    }

    func setFeaturedImage(from items: [MediaPickerSelection]) {
        guard let item = items.first else {
            return wpAssertionFailure("selection is empty")
        }

    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
}
