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
    var configuration = MediaPickerConfiguration()
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
            Button {
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
        let menu = MediaPickerMenu(
            viewController: presentingViewController ?? UIViewController(),
            filter: configuration.filter,
            isMultipleSelectionEnabled: configuration.isMultipleSelectionEnabled
        )

        let controller = MediaPickerMenuController()
        controller.onSelection = onSelection
        viewModel.controller = controller // Needs to be retained

        return configuration.sources.compactMap { source in
            switch source {
            case .photos:
                return menu.makePhotosAction(delegate: controller)
            case .camera:
                return menu.makeCameraAction(delegate: controller)
            case .siteMedia(let blog):
                return menu.makeSiteMediaAction(blog: blog, delegate: controller)
            case .playground:
                return menu.makeImagePlaygroundAction(delegate: controller)
            case .freePhotos(let blog):
                return menu.makeStockPhotos(blog: blog, delegate: controller)
            case .freeGIFs(let blog):
                return menu.makeFreeGIFAction(blog: blog, delegate: controller)

            }
        }
    }
}

struct MediaPickerConfiguration {
    var sources: [MediaPickerSource] = [.photos, .camera]
    var filter: MediaPickerMenu.MediaFilter?
    var isMultipleSelectionEnabled = false
}

private final class MediaPickerViewModel: ObservableObject {
    var controller: MediaPickerMenuController?
}

enum MediaPickerSource {
    case photos // Apple Photos
    case camera
    case siteMedia(blog: Blog)
    case playground // Image Playground
    case freePhotos(blog: Blog) // Pexels
    case freeGIFs(blog: Blog) // Tenor
}

struct MediaPickerSelection {
    var items: [MediaPickerItem]
    var source: String
}

enum MediaPickerItem {
    case pickerResult(PHPickerResult)
    case image(UIImage)
    case media(Media)
    case external(ExternalMediaAsset)

    /// Prepares the item for export and upload to your site media. If the item
    /// is already uploaded, returns `Media`.
    func exported() -> Exportable {
        switch self {
        case .pickerResult(let result):
            return .asset(result.itemProvider)
        case .image(let image):
            return .asset(image)
        case .media(let media):
            return .media(media)
        case .external(let asset):
            return .asset(asset)
        }
    }

    enum Exportable {
        case asset(ExportableAsset)
        case media(Media)
    }
}
