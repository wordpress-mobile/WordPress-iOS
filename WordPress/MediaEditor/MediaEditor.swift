import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController

    private(set) var cropViewController: TOCropViewController?
    private var callback: ((UIImage?) -> ())?

    public init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init) {
        self.cropViewControllerFactory = cropViewControllerFactory
        super.init()
    }

    public func edit(_ image: UIImage, from viewController: UIViewController? = nil, callback: @escaping (UIImage?) -> ()) {
        self.callback = callback
        let cropViewController = self.cropViewControllerFactory(image)
        cropViewController.delegate = self
        viewController?.present(cropViewController, animated: true)
        self.cropViewController = cropViewController
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
