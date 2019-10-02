import Foundation
import CoreServices
import WPMediaPicker
import Gutenberg

public typealias GutenbergMediaPickerHelperCallback = ([WPMediaAsset]?) -> Void

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
        options.filter = [.image]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.allowMultipleSelection = false
        options.preferredStatusBarStyle = .lightContent
        return options
    }()

    var didPickMediaCallback: GutenbergMediaPickerHelperCallback?

    init(context: UIViewController, post: AbstractPost) {
        self.context = context
        self.post = post
    }

    func presentMediaPickerFullScreen(animated: Bool,
                                      filter: WPMediaType,
                                      dataSourceType: MediaPickerDataSourceType = .device,
                                      allowMultipleSelection: Bool,
                                      callback: @escaping GutenbergMediaPickerHelperCallback) {

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
        mediaPickerOptions.filter = filter
        mediaPickerOptions.allowMultipleSelection = allowMultipleSelection
        picker.mediaPicker.options = mediaPickerOptions
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext
        context.present(picker, animated: true)
    }

    private lazy var cameraPicker: WPMediaPickerViewController = {
        let cameraPicker = WPMediaPickerViewController()
        cameraPicker.options = mediaPickerOptions
        cameraPicker.mediaPickerDelegate = self
        cameraPicker.dataSource = WPPHAssetDataSource.sharedInstance()
        return cameraPicker
    }()

    func presentCameraCaptureFullScreen(animated: Bool,
                                        filter: WPMediaType,
                                        callback: @escaping GutenbergMediaPickerHelperCallback) {

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            callback(nil)
            return
        }

        didPickMediaCallback = callback
        //reset the selected assets from previous uses
        cameraPicker.resetState(false)
        cameraPicker.modalPresentationStyle = .currentContext
        cameraPicker.viewControllerToUseToPresent = context
        cameraPicker.options.filter = filter
        cameraPicker.showCapture()
    }
}

extension GutenbergMediaPickerHelper: WPMediaPickerViewControllerDelegate {

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        invokeMediaPickerCallback(asset: assets)
        picker.dismiss(animated: true, completion: nil)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        context.dismiss(animated: true, completion: { self.invokeMediaPickerCallback(asset: nil) })
    }

    fileprivate func invokeMediaPickerCallback(asset: [WPMediaAsset]?) {
        didPickMediaCallback?(asset)
        didPickMediaCallback = nil
    }
}
