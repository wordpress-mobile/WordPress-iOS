import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController

    private var cropViewController: TOCropViewController?
    private var onFinishEditing: ((UIImage, [MediaEditorOperation]) -> ())?
    private var onCancel: (() -> ())?

    public init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init) {
        self.cropViewControllerFactory = cropViewControllerFactory
        super.init()
    }

    public func edit(_ image: UIImage, from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        let cropViewController = cropViewControllerFactory(image)
        cropViewController.delegate = self
        cropViewController.toolbar.rotateCounterclockwiseButtonHidden = true
        viewController?.present(cropViewController, animated: true)
        self.cropViewController = cropViewController
    }

    public func dismiss(animated: Bool, completion: (() -> ())? = nil) {
        cropViewController?.dismiss(animated: animated, completion: completion)
    }

    private func releaseCallbacks() {
        onFinishEditing = nil
        onCancel = nil
    }

}

// MARK: - TOCropViewControllerDelegate

extension MediaEditor: TOCropViewControllerDelegate {

    public func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        let operations = self.operations(with: cropRect, angle: angle)
        onFinishEditing?(image, operations)
        releaseCallbacks()
    }

    public func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        self.cropViewController?.dismiss(animated: true)
        onCancel?()
        releaseCallbacks()
    }

    private func operations(with cropRect: CGRect, angle: Int) -> [MediaEditorOperation] {
        var operations: [MediaEditorOperation] = []

        if isCropped {
            operations.append(.crop)
        }

        if isRotated {
            operations.append(.rotate)
        }

        return operations
    }
}

// MARK: - Cropping/Resizing properties

extension MediaEditor {
    // TOCropViewController sometimes resize the image by 1, 2 or 3 points automatically.
    // In those cases we're not considering that as a cropping action.
    var isCropped: Bool {
        guard let cropViewController = cropViewController else {
            return false
        }

        return abs(imageSizeDiscardingRotation.width - cropViewController.image.size.width) > 4 ||
            abs(imageSizeDiscardingRotation.height - cropViewController.image.size.height) > 4
    }

    var imageSizeDiscardingRotation: CGSize {
        guard let cropViewController = cropViewController else {
            return .zero
        }

        let imageSize = cropViewController.imageCropFrame.size

        let anglesThatChangesImageSize = [90, 270]
        if anglesThatChangesImageSize.contains(cropViewController.angle) {
            return CGSize(width: imageSize.height, height: imageSize.width)
        } else {
            return imageSize
        }
    }

    var isRotated: Bool {
        guard let cropViewController = cropViewController else {
            return false
        }

        return cropViewController.angle != 0
    }
}
