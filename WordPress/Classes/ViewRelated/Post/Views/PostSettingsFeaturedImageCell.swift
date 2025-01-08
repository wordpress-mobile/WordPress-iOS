import SwiftUI
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel

    var body: some View {
        MediaPicker(filter: .images) {
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
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
}
