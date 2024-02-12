import Foundation
import CoreServices
import UIKit
import Photos
import PhotosUI
import WordPressShared
import Gutenberg
import UniformTypeIdentifiers

public typealias GutenbergMediaPickerHelperCallback = ([Any]?) -> Void

final class GutenbergMediaPickerHelper: NSObject {
    private let post: AbstractPost
    private unowned let context: UIViewController

    /// Media Library Data Source

    var didPickMediaCallback: GutenbergMediaPickerHelperCallback?

    init(context: UIViewController, post: AbstractPost) {
        self.context = context
        self.post = post
    }

    func presetDevicePhotosPicker(filter: WPMediaType, allowMultipleSelection: Bool, completion: @escaping GutenbergMediaPickerHelperCallback) {
        didPickMediaCallback = completion

        var configuration = PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .current
        if allowMultipleSelection {
            configuration.selection = .ordered
            configuration.selectionLimit = 0
        }
        configuration.filter = PHPickerFilter(filter)

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        context.present(picker, animated: true)
    }

    func presentSiteMediaPicker(filter: WPMediaType, allowMultipleSelection: Bool, completion: @escaping GutenbergMediaPickerHelperCallback) {
        didPickMediaCallback = completion
        MediaPickerMenu(viewController: context, filter: .init(filter), isMultipleSelectionEnabled: allowMultipleSelection)
            .showSiteMediaPicker(blog: post.blog, delegate: self)
    }

    func presentCameraCaptureFullScreen(animated: Bool,
                                        filter: WPMediaType,
                                        callback: @escaping GutenbergMediaPickerHelperCallback) {
        didPickMediaCallback = callback
        MediaPickerMenu(viewController: context, filter: .init(filter))
            .showCamera(delegate: self)
    }
}

extension GutenbergMediaPickerHelper: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        context.dismiss(animated: true) {
            guard let mediaType = info[.mediaType] as? String else {
                return
            }
            switch mediaType {
            case UTType.image.identifier:
                if let image = info[.originalImage] as? UIImage {
                    self.didPickMediaCallback?([image])
                    self.didPickMediaCallback = nil
                }

            case UTType.movie.identifier:
                guard let videoURL = info[.mediaURL] as? URL else {
                    return
                }
                guard self.post.blog.canUploadVideo(from: videoURL) else {
                    self.presentVideoLimitExceededAfterCapture(on: self.context)
                    return
                }
                self.didPickMediaCallback?([videoURL])
                self.didPickMediaCallback = nil
            default:
                break
            }
        }
    }
}

extension GutenbergMediaPickerHelper: VideoLimitsAlertPresenter {}

extension GutenbergMediaPickerHelper: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        context.dismiss(animated: true)
        didPickMediaCallback?(selection)
        didPickMediaCallback = nil
    }
}

extension GutenbergMediaPickerHelper: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        context.dismiss(animated: true)

        guard results.count > 0 else {
            return
        }

        didPickMediaCallback?(results.map(\.itemProvider))
        didPickMediaCallback = nil
    }
}
