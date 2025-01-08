import SwiftUI
import WordPressUI

struct PostSettingsFeaturedImageCell: View {
//    @ObservedObject var viewModel: PostSettingsFeaturedImageViewModel
//    weak var presentingViewController: UIViewController?

    var body: some View {
        MediaPicker(filter: .images) {
            Label(Strings.buttonSetFeaturedImage, systemImage: "photo.badge.plus")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle()) // Make the whole cell tappable
        }
    }
}

final class PostSettingsFeaturedImageViewModel: ObservableObject {
    @Published var isUploading = false

    @Published private var state: State = .empty

    enum State {
        case empty
        // TODO: show PostMediaUploadsView
        case uploading
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
}
