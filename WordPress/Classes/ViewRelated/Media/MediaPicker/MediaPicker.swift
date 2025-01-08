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
    var sources: [MediaPickerSource] = [.photos, .camera]
    var filter: MediaPickerMenu.MediaFilter?
    var isMultipleSelectionEnabled: Bool = false
    var onSelection: ((MediaPickerSelection) -> Void)?

    @ViewBuilder var content: () -> Content

    @StateObject private var viewModel = MediaPickerViewModel()

    @Environment(\.presentingViewController) var presentingViewController

    var body: some View {
        Menu {
            menu
        } label: {
            content()
        }
    }

    @ViewBuilder
    private var menu: some View {
        ForEach(makeActions(), id: \.self) { action in
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

    private func makeActions() -> [UIAction] {
        let menu = MediaPickerMenu(viewController: presentingViewController ?? UIViewController(), filter: filter)

        let controller = MediaPickerMenuController()
        controller.onSelection = onSelection
        viewModel.controller = controller // Needs to be retained

        return sources.map { source in
            switch source {
            case .photos: menu.makePhotosAction(delegate: controller)
            case .camera: menu.makeCameraAction(delegate: controller)
            }
        }
//        let actions: [UIAction] = [
//            menu.makePhotosAction(delegate: controller),
//            menu.makeCameraAction(delegate: controller),
//            // TODO: implement
//            //
//            //            menu.makeImagePlaygroundAction(delegate: delegate),
//            //                menu.makeSiteMediaAction(blog: self.apost.blog, delegate: delegate)
//        ]
    }
}

private final class MediaPickerViewModel: ObservableObject {
    var controller: MediaPickerMenuController?
}

enum MediaPickerSource {
    case photos
    case camera

    var analyticsValue: String {
        switch self {
        case .photos: "apple_photos"
        case .camera: "camera"
        }
    }
}

struct MediaPickerSelection {
    var items: [MediaPickerItem]
    var source: MediaPickerSource
}

enum MediaPickerItem {
    case pickerResult(PHPickerResult)
    case image(UIImage)

    var exportableAsset: ExportableAsset {
        switch self {
        case .pickerResult(let result):
            return result.itemProvider
        case .image(let image):
            return image
        }
    }
}
