import WPMediaPicker
import MobileCoreServices
import CoreGraphics
import Photos
import UniformTypeIdentifiers

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
        options.badgedUTTypes = [UTType.gif.identifier]
        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle

        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.dataSource = dataSource
        picker.delegate = delegate
        picker.mediaPicker.registerClass(forReusableCellOverlayViews: DisabledVideoOverlay.self)
        picker.mediaPicker.registerClass(forCustomHeaderView: DeviceMediaPermissionsHeader.self)

        origin.present(picker, animated: true)
    }
}

/// An overlay for videos that exceed allowed duration
class DisabledVideoOverlay: UIView {

    static let overlayTransparency: CGFloat = 0.8

    init() {
        super.init(frame: .zero)
        backgroundColor = .gray.withAlphaComponent(Self.overlayTransparency)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
