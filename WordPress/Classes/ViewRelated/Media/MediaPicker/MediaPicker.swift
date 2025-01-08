import SwiftUI
import Photos
import PhotosUI
import WordPressUI

/// A media picker menu.
///
/// - note: Use `.environment(\.presentingViewController, <#vc#>)` to pass the
/// presenting view controller. If not provided, the current top view controller
/// is used.
struct MediaPicker<Content: View>: View {
    var filter: MediaPickerMenu.MediaFilter?
    var isMultipleSelectionEnabled: Bool = false
    var initialSelection: [Media] = []

    @Environment(\.presentingViewController) var presentingViewController

    var body: some View {
        Menu {
            actions
        } label: {
            // TODO: make customizable
            Text("Set Image")
        }
    }

    @ViewBuilder
    private var actions: some View {
        let menu = MediaPickerMenu(viewController: presentingViewController ?? UIViewController(), filter: filter)
        let delegate = MediaPickerMenuDelegate()
        let actions: [UIAction] = [
            menu.makePhotosAction(delegate: delegate),
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
}

enum MediaPickerSource {
    /// Apple Photos app.
    case photos
}

private final class MediaPickerMenuDelegate: NSObject {}

extension MediaPickerMenuDelegate: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // TODO:
    }

    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // TODO:
    }
}

extension MediaPickerMenuDelegate: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        // TODO:
    }
}

extension MediaPickerMenuDelegate: ImagePlaygroundPickerDelegate {
    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL) {
        // TODO:
    }
}
