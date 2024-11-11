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

    func presentSiteMediaPicker(filter: WPMediaType, allowMultipleSelection: Bool, initialSelection: [Int] = [], completion: @escaping GutenbergMediaPickerHelperCallback) {
        didPickMediaCallback = completion
        let initialMediaSelection = mapMediaIdsToMedia(initialSelection)
        MediaPickerMenu(viewController: context, filter: .init(filter), isMultipleSelectionEnabled: allowMultipleSelection, initialSelection: initialMediaSelection)
            .showSiteMediaPicker(blog: post.blog, delegate: self)
    }

    private func mapMediaIdsToMedia(_ mediaIds: [Int]) -> [Media] {
        assert(Thread.isMainThread, "mapMediaIdsToMedia should only be called on the main thread")
        let context = ContextManager.shared.mainContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Media")
        request.predicate = NSPredicate(format: "mediaID IN %@", mediaIds.map { NSNumber(value: $0) })

        do {
            let fetchedMedia = try context.fetch(request) as? [Media] ?? []

            // Create a dictionary for quick lookup
            let mediaDict = Dictionary(uniqueKeysWithValues: fetchedMedia.compactMap { media -> (Int, Media)? in
                if let mediaID = media.mediaID?.intValue {
                    return (mediaID, media)
                }
                return nil
            })

            // Map the original mediaIds to Media objects, preserving order
            return mediaIds.compactMap { mediaDict[$0] }
        } catch {
            return []
        }
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
