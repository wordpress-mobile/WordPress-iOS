import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController

    private(set) var cropViewController: TOCropViewController?
    private var callback: ((UIImage?) -> ())?

    init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init) {
        self.cropViewControllerFactory = cropViewControllerFactory
        super.init()
    }

    public func edit(_ image: UIImage, callback: @escaping (UIImage?) -> ()) {
        self.callback = callback
        cropViewController = self.cropViewControllerFactory(image)
        cropViewController?.delegate = self
    }

}

extension MediaEditor: TOCropViewControllerDelegate {
    public func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        callback?(image)
    }

    public func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        self.cropViewController?.dismiss(animated: true)
        callback?(nil)
    }
}
