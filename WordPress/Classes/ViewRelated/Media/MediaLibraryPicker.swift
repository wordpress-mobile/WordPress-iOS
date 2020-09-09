import WPMediaPicker
import MobileCoreServices

/// Encapsulates launching and customization of a media picker to import media from the Photos Library
final class MediaLibraryPicker: NSObject {
    private let dataSource = WPPHAssetDataSource()

    weak var delegate: WPMediaPickerViewControllerDelegate?
    private var blog: Blog?

    func presentPicker(origin: UIViewController, blog: Blog) {
        self.blog = blog
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle

        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.dataSource = dataSource
        picker.delegate = delegate

        origin.present(picker, animated: true)
    }
}
