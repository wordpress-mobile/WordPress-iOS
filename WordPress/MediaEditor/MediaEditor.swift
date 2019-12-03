import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController
    let image: UIImage

    private lazy var cropViewController: TOCropViewController = {
        return cropViewControllerFactory(image)
    }()
    private var onFinishEditing: ((UIImage, [MediaEditorOperation]) -> ())?
    private var onCancel: (() -> ())?

    public init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init, image: UIImage) {
        self.cropViewControllerFactory = cropViewControllerFactory
        self.image = image
        super.init()
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        cropViewController.delegate = self
        cropViewController.toolbar.rotateCounterclockwiseButtonHidden = true
        viewController?.present(cropViewController, animated: true)
    }

    public func dismiss(animated: Bool, completion: (() -> ())? = nil) {
        cropViewController.dismiss(animated: animated, completion: completion)
    }

    private func releaseCallbacks() {
        onFinishEditing = nil
        onCancel = nil
    }

}

// MARK: - TOCropViewControllerDelegate

extension MediaEditor: TOCropViewControllerDelegate {

    public func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        let actions = cropViewController.actions
        onFinishEditing?(image, actions)
        releaseCallbacks()
    }

    public func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        self.cropViewController.dismiss(animated: true)
        onCancel?()
        releaseCallbacks()
    }
}
