import UIKit

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
        alert.addAction(UIAlertAction(title: SharedStrings.Button.ok, style: .cancel))
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

private enum Strings {
    static let takePhoto = NSLocalizedString("mediaPicker.takePhoto", value: "Take Photo", comment: "The name of the action in the context menu")
    static let takeVideo = NSLocalizedString("mediaPicker.takeVideo", value: "Take Video", comment: "The name of the action in the context menu")
    static let takePhotoOrVideo = NSLocalizedString("mediaPicker.takePhotoOrVideo", value: "Take Photo or Video", comment: "The name of the action in the context menu")
    static let noCameraAccessTitle = NSLocalizedString("mediaPicker.noCameraAccessTitle", value: "Media Capture", comment: "Title for alert when access to camera is not granted")
    static let noCameraAccessMessage = NSLocalizedString("mediaPicker.noCameraAccessMessage", value: "This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", comment: "Message for alert when access to camera is not granted")
    static let noCameraOpenSettings = NSLocalizedString("mediaPicker.openSettings", value: "Open Settings", comment: "Button that opens the Settings app")
}
