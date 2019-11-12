import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController

    private var cropViewController: TOCropViewController?
    private var onFinishEditing: ((UIImage?) -> ())?
    private var onCancel: (() -> ())?

    public init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init) {
        self.cropViewControllerFactory = cropViewControllerFactory
        super.init()
    }

    public func edit(_ image: UIImage, from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage?) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        let cropViewController = self.cropViewControllerFactory(image)
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
        onFinishEditing = nil
    }

}

extension MediaEditor: TOCropViewControllerDelegate {
    public func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        onFinishEditing?(image)
        releaseCallbacks()
    }

    public func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        self.cropViewController?.dismiss(animated: true)
        onCancel?()
        releaseCallbacks()
    }
}
