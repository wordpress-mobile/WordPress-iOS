import UIKit
import TOCropViewController

class MediaEditorCrop: MediaEditorCapability {
    var image: UIImage

    var onFinishEditing: (UIImage, [MediaEditorOperation]) -> ()

    var onCancel: (() -> ())

    lazy var viewController: UIViewController = {
        let cropViewController = TOCropViewController(image: image)

        cropViewController.hidesNavigationBar = false

        cropViewController.onDidCropToRect = { image, cropRect, angle in
            self.onFinishEditing(image, cropViewController.actions)
        }

        cropViewController.onDidFinishCancelled = { _ in
            self.onCancel()
        }

        return cropViewController
    }()

    required init(_ image: UIImage,
                  onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (),
                  onCancel: @escaping () -> ()) {
        self.image = image
        self.onFinishEditing = onFinishEditing
        self.onCancel = onCancel
    }

    func apply(styles: MediaEditorStyles) {
        guard let viewController = viewController as? TOCropViewController else {
            return
        }

        if let doneLabel = styles[.doneLabel] as? String {
            viewController.toolbar.doneTextButton.setTitle(doneLabel, for: .normal)
        }

        if let cancelLabel = styles[.cancelLabel] as? String {
            viewController.toolbar.cancelTextButton.setTitle(cancelLabel, for: .normal)
        }

        if let cancelColor = styles[.cancelColor] as? UIColor {
            viewController.toolbar.cancelTextButton.tintColor = cancelColor
            viewController.toolbar.cancelIconButton.tintColor = cancelColor
        }

        if let resetIcon = styles[.resetIcon] as? UIImage {
            viewController.toolbar.resetButton.setImage(resetIcon, for: .normal)
        }

        if let doneIcon = styles[.doneIcon] as? UIImage {
            viewController.toolbar.doneIconButton.setImage(doneIcon, for: .normal)
        }

        if let cancelIcon = styles[.cancelIcon] as? UIImage {
            viewController.toolbar.cancelIconButton.setImage(cancelIcon, for: .normal)
        }

        if let rotateClockwiseIcon = styles[.rotateClockwiseIcon] as? UIImage {
            viewController.toolbar.rotateClockwiseButton?.setImage(rotateClockwiseIcon, for: .normal)
        }

        if let rotateCounterclockwiseButtonHidden = styles[.rotateCounterclockwiseButtonHidden] as? Bool {
            viewController.toolbar.rotateCounterclockwiseButtonHidden = rotateCounterclockwiseButtonHidden
        }
    }
}
