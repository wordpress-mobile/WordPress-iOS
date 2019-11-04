import UIKit
import TOCropViewController

public class MediaEditor: NSObject {

    let cropViewControllerFactory: (UIImage) -> TOCropViewController

    private(set) var cropViewController: TOCropViewController?

    init(cropViewControllerFactory: @escaping (UIImage) -> TOCropViewController = TOCropViewController.init) {
        self.cropViewControllerFactory = cropViewControllerFactory
        super.init()
    }

    public func edit(_ image: UIImage) {
        cropViewController = self.cropViewControllerFactory(image)
        cropViewController?.delegate = self
    }

}

extension MediaEditor: TOCropViewControllerDelegate {
    public func cropViewController(_ cropViewController: TOCropViewController, didCropImageTo cropRect: CGRect, angle: Int) {

    }
}
