import Foundation
import CoreServices
import WPMediaPicker
import Gutenberg

class GutenbergMediaPickerHelper: NSObject {

    fileprivate struct Constants {
        static let mediaPickerInsertText = NSLocalizedString(
            "Insert %@",
            comment: "Button title used in media picker to insert media (photos / videos) into a post. Placeholder will be the number of items that will be inserted."
        )
    }

    fileprivate let post: AbstractPost
    fileprivate unowned let context: UIViewController

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: MediaLibraryPickerDataSource = {
        return MediaLibraryPickerDataSource(post: self.post)
    }()

    /// Device Photo Library Data Source
    ///
    fileprivate lazy var devicePhotoLibraryDataSource = WPPHAssetDataSource()

    fileprivate lazy var mediaPickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.allowMultipleSelection = false
        return options
    }()

    var didPickMediaCallback: MediaPickerDidPickMediaCallback?

    init(context: UIViewController, post: AbstractPost) {
        self.context = context
        self.post = post
    }

    func presentMediaPickerFullScreen(animated: Bool,
                                      dataSourceType: MediaPickerDataSourceType = .device,
                                      callback: @escaping MediaPickerDidPickMediaCallback) {

        didPickMediaCallback = callback

        let picker = WPNavigationMediaPickerViewController()

        switch dataSourceType {
        case .device:
            picker.dataSource = devicePhotoLibraryDataSource
        case .mediaLibrary:
            picker.startOnGroupSelector = false
            picker.showGroupSelector = false
            picker.dataSource = mediaLibraryDataSource
        }

        picker.selectionActionTitle = Constants.mediaPickerInsertText
        picker.mediaPicker.options = mediaPickerOptions
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext
        context.present(picker, animated: true)
    }
}

extension GutenbergMediaPickerHelper: WPMediaPickerViewControllerDelegate {

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {

        guard !assets.isEmpty else {
            return
        }

        for asset in assets {
            switch asset {
            case let media as Media:
                invokeMediaPickerCallback(url: media.remoteURL)
            default:
                continue
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        invokeMediaPickerCallback(url: nil)
        picker.dismiss(animated: true, completion: nil)
    }

    fileprivate func invokeMediaPickerCallback(url: String?) {
        didPickMediaCallback?(url)
        didPickMediaCallback = nil
    }
}
