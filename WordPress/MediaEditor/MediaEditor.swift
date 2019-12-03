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

    public var cancelTextButton: UIButton {
        return cropViewController.toolbar.cancelTextButton
    }

    public var resetButton: UIButton {
        return cropViewController.toolbar.resetButton
    }

    public var doneIconButton: UIButton {
        return cropViewController.toolbar.doneIconButton
    }

    public var cancelIconButton: UIButton {
        return cropViewController.toolbar.cancelIconButton
    }

    public var rotateClockwiseButton: UIButton? {
        return cropViewController.toolbar.rotateClockwiseButton
    }

    public var rotateCounterclockwiseButton: UIButton? {
        return cropViewController.toolbar.rotateCounterclockwiseButton
    }

    public var rotateCounterclockwiseButtonHidden: Bool {
        get {
            return cropViewController.toolbar.rotateCounterclockwiseButtonHidden
        }

        set {
            cropViewController.toolbar.rotateCounterclockwiseButtonHidden = newValue
        }
    }

    public var rotateClockwiseButtonHidden: Bool {
        get {
            return cropViewController.toolbar.rotateClockwiseButtonHidden
        }

        set {
            cropViewController.toolbar.rotateClockwiseButtonHidden = newValue
        }
    }

    public init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init, image: UIImage) {
        self.cropViewControllerFactory = cropViewControllerFactory
        self.image = image
        super.init()
    }

    public func edit(from viewController: UIViewController? = nil, onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (), onCancel: (() -> ())? = nil) {
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
        cropViewController.delegate = self
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
