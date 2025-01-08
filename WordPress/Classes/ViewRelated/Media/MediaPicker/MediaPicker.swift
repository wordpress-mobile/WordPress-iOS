import SwiftUI
import WordPressUI
import Photos
import PhotosUI

/// A media picker menu.
///
/// - note: Use `.environment(\.presentingViewController, <#vc#>)` to pass the
/// presenting view controller. If not provided, the current top view controller
/// is used.
struct MediaPicker<Content: View>: View {
    var filter: MediaPickerMenu.MediaFilter?
    var isMultipleSelectionEnabled: Bool = false
    var initialSelection: [Media] = []
    var onSelection: (([MediaPickerSelection]) -> Void)?

    @ViewBuilder var content: () -> Content

    @StateObject private var viewModel = MediaPickerViewModel()

    @Environment(\.presentingViewController) var presentingViewController

    var body: some View {
        Menu {
            actions
        } label: {
            content()
        }
    }

    @ViewBuilder
    private var actions: some View {
        let menu = MediaPickerMenu(viewController: presentingViewController ?? UIViewController(), filter: filter)
        let controller = makeMediaPickerMenuController()
        let actions: [UIAction] = [
            menu.makePhotosAction(delegate: controller),
            // TODO: implement
//            menu.makeCameraAction(delegate: delegate),
//            menu.makeImagePlaygroundAction(delegate: delegate),
        //                menu.makeSiteMediaAction(blog: self.apost.blog, delegate: delegate)
        ]
        ForEach(actions, id: \.self) { action in
            Button.init {
                action.performWithSender(nil, target: nil)
            } label: {
                Label {
                    Text(action.title)
                } icon: {
                    action.image.map(Image.init)
                }

            }
        }
    }

    private func makeMediaPickerMenuController() -> MediaPickerMenuController {
        let controller = MediaPickerMenuController()
        controller.onSelection = onSelection
        viewModel.controller = controller // Needs to be retained
        return controller
    }
}

private final class MediaPickerViewModel: ObservableObject {
    var controller: MediaPickerMenuController?
}

enum MediaPickerSource {
    /// Apple Photos app.
    case applePhotos
}

enum MediaPickerSelection {
    case phPickerResult(PHPickerResult)
}
