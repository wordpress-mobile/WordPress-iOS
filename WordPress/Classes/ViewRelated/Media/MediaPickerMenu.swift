import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import CocoaLumberjack

/// A convenience API for creating actions for picking media from different
/// source supported by the app: Photos library, Camera, Media library.
struct MediaPickerMenu {
    weak var presentingViewController: UIViewController?
    var filter: MediaFilter?
    var isMultipleSelectionEnabled: Bool

    enum MediaFilter {
        case images
        case videos
    }

    /// Initializes the options.
    ///
    /// - parameters:
    ///   - viewController: The view controller to use for presentation.
    ///   - filter: By default, `nil` – allow all content types.
    ///   - isMultipleSelectionEnabled: By default, `false`.
    init(viewController: UIViewController,
         filter: MediaFilter? = nil,
         isMultipleSelectionEnabled: Bool = false) {
        self.presentingViewController = viewController
        self.filter = filter
        self.isMultipleSelectionEnabled = isMultipleSelectionEnabled
    }
}

// MARK: - MediaPickerMenu (Photos)

extension MediaPickerMenu {
    /// Returns an action for picking photos from the device's Photos library.
    ///
    /// - note: Use `PHPickerResult.loadImage(for:)` to retrieve an image from the result.
    func makePhotosAction(delegate: PHPickerViewControllerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromPhotosLibrary,
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            attributes: [],
            handler: { _ in showPhotosPicker(delegate: delegate) }
        )
    }

    func showPhotosPicker(delegate: PHPickerViewControllerDelegate) {
        var configuration = PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .current
        if let filter {
            switch filter {
            case .images:
                configuration.filter = .images
            case .videos:
                configuration.filter = .videos
            }
        }
        if isMultipleSelectionEnabled {
            configuration.selectionLimit = 0
            configuration.selection = .ordered
        }
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = delegate
        presentingViewController?.present(picker, animated: true)
    }
}

// MARK: - MediaPickerMenu (Camera)

protocol ImagePickerControllerDelegate: AnyObject {
    // Hides `NSObject` and `UINavigationControllerDelegate` conformances that
    // the original `UIImagePickerControllerDelegate` has.

    /// - parameter info: If the info is empty, nothing was selected.
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
}

extension MediaPickerMenu {
    /// Returns an action from capturing media using the device's camera.
    ///
    /// - parameters:
    ///   - camera: The camera to use. By default, `.rear`.
    ///   - delegate: The delegate.
    func makeCameraAction(
        camera: UIImagePickerController.CameraDevice = .rear,
        delegate: ImagePickerControllerDelegate
    ) -> UIAction {
        UIAction(
            title: cameraActionTitle,
            image: UIImage(systemName: "camera"),
            attributes: [],
            handler: { _ in showCamera(camera: camera, delegate: delegate) }
        )
    }

    private var cameraActionTitle: String {
        guard let filter else {
            return Strings.takePhotoOrVideo
        }
        switch filter {
        case .images: return Strings.takePhoto
        case .videos: return Strings.takeVideo
        }
    }

    func showCamera(camera: UIImagePickerController.CameraDevice = .rear, delegate: ImagePickerControllerDelegate) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined:
            actuallyShowCamera(camera: camera, delegate: delegate)
        case .restricted, .denied:
            showAccessRestrictedAlert()
        @unknown default:
            showAccessRestrictedAlert()
        }
    }

    private func actuallyShowCamera(camera: UIImagePickerController.CameraDevice, delegate: ImagePickerControllerDelegate) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = camera
        picker.videoQuality = .typeHigh
        if let filter {
            switch filter {
            case .images: picker.mediaTypes = [UTType.image.identifier]
            case  .videos: picker.mediaTypes = [UTType.movie.identifier]
            }
        } else {
            picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        }

        let delegate = ImagePickerDelegate(delegate: delegate)
        picker.delegate = delegate
        objc_setAssociatedObject(picker, &MediaPickerMenu.strongDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        presentingViewController?.present(picker, animated: true)
    }

    private func showAccessRestrictedAlert() {
        let alert = UIAlertController(title: Strings.noCameraAccessTitle, message: Strings.noCameraAccessMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.buttonOK, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.noCameraOpenSettings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return assertionFailure("Failed to create Open Settigns URL")
            }
            UIApplication.shared.open(url)
        })
        presentingViewController?.present(alert, animated: true)
    }


    private final class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        weak var delegate: ImagePickerControllerDelegate?

        init(delegate: ImagePickerControllerDelegate) {
            self.delegate = delegate
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            delegate?.imagePicker(picker, didFinishPickingMediaWithInfo: info)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            delegate?.imagePicker(picker, didFinishPickingMediaWithInfo: [:])
        }
    }

    private static var strongDelegateKey: UInt8 = 0
}

// MARK: - MediaPickerMenu (Site Media)

extension MediaPickerMenu {
    /// Returns an action for selecting media from the media uploaded by the user
    /// to their site.
    func makeSiteMediaAction(blog: Blog, delegate: SiteMediaPickerViewControllerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromMedia,
            image: UIImage(systemName: "photo.stack"),
            attributes: [],
            handler: { _ in showSiteMediaPicker(blog: blog, delegate: delegate) }
        )
    }

    func showSiteMediaPicker(blog: Blog, delegate: SiteMediaPickerViewControllerDelegate) {
        let viewController = SiteMediaPickerViewController(
            blog: blog,
            filter: filter.map { [$0.mediaType] },
            allowsMultipleSelection: isMultipleSelectionEnabled
        )
        viewController.delegate = delegate
        let navigation = UINavigationController(rootViewController: viewController)
        presentingViewController?.present(navigation, animated: true)
    }
}


// MARK: - MediaPickerMenu (Stock Photo)

extension MediaPickerMenu {
    func makeStockPhotos(blog: Blog, delegate: StockPhotosPickerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromStockPhotos,
            image: UIImage(systemName: "photo.on.rectangle"),
            attributes: [],
            handler: { _ in showStockPhotosPicker(blog: blog, delegate: delegate) }
        )
    }

    func showStockPhotosPicker(blog: Blog, delegate: StockPhotosPickerDelegate) {
        guard let presentingViewController else { return }

        let picker = StockPhotosPicker()
        picker.delegate = delegate
        picker.allowMultipleSelection = isMultipleSelectionEnabled
        let stockPhotosViewController = picker.presentPicker(origin: presentingViewController, blog: blog)

        objc_setAssociatedObject(stockPhotosViewController, &MediaPickerMenu.dataSourceAssociatedKey, picker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static var dataSourceAssociatedKey: UInt8 = 0
}

// MARK: - MediaPickerMenu (Free GIF, Tenor)

extension MediaPickerMenu {
    func makeFreeGIFAction(blog: Blog, delegate: ExternalMediaPickerViewDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromTenor,
            image: UIImage(systemName: "play.square.stack"),
            attributes: [],
            handler: { _ in showFreeGIFPicker(blog: blog, delegate: delegate) }
        )
    }

    func showFreeGIFPicker(blog: Blog, delegate: ExternalMediaPickerViewDelegate) {
        guard let presentingViewController else { return }

        let picker = ExternalMediaPickerViewController(
            dataSource: TenorDataSource(service: TenorService()),
            allowsMultipleSelection: isMultipleSelectionEnabled
        )
        picker.title = Strings.pickFromTenor
        picker.welcomeView = TenorWelcomeView()
        picker.delegate = delegate

        let navigation = UINavigationController(rootViewController: picker)
        presentingViewController.present(navigation, animated: true)
    }
}

extension MediaPickerMenu.MediaFilter {
    init?(_ mediaType: WPMediaType) {
        switch mediaType {
        case .image: self = .images
        case .video: self = .videos
        default: return nil
        }
    }

    var mediaType: MediaType {
        switch self {
        case .images: return .image
        case .videos: return .video
        }
    }
}

private enum Strings {
    // MARK: Actions

    static let pickFromPhotosLibrary = NSLocalizedString("mediaPicker.pickFromPhotosLibrary", value: "Choose from Device", comment: "The name of the action in the context menu")
    static let takePhoto = NSLocalizedString("mediaPicker.takePhoto", value: "Take Photo", comment: "The name of the action in the context menu")
    static let takeVideo = NSLocalizedString("mediaPicker.takeVideo", value: "Take Video", comment: "The name of the action in the context menu")
    static let takePhotoOrVideo = NSLocalizedString("mediaPicker.takePhotoOrVideo", value: "Take Photo or Video", comment: "The name of the action in the context menu")
    static let pickFromMedia = NSLocalizedString("mediaPicker.pickFromMediaLibrary", value: "Choose from Media", comment: "The name of the action in the context menu (user's WordPress Media Library")
    static let pickFromStockPhotos = NSLocalizedString("mediaPicker.pickFromStockPhotos", value: "Free Photo Library", comment: "The name of the action in the context menu for selecting photos from free stock photos")
    static let pickFromTenor = NSLocalizedString("mediaPicker.pickFromFreeGIFLibrary", value: "Free GIF Library", comment: "The name of the action in the context menu for selecting photos from Tenor (free GIF library)")

    // MARK: Misc

    static let noCameraAccessTitle = NSLocalizedString("mediaPicker.noCameraAccessTitle", value: "Media Capture", comment: "Title for alert when access to camera is not granted")
    static let noCameraAccessMessage = NSLocalizedString("mediaPicker.noCameraAccessMessage", value: "This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", comment: "Message for alert when access to camera is not granted")
    static let noCameraOpenSettings = NSLocalizedString("mediaPicker.openSettings", value: "Open Settings", comment: "Button that opens the Settings app")
    static let buttonOK = NSLocalizedString("OK", value: "OK", comment: "OK")
}
