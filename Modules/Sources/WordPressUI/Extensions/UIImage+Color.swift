import UIKit

public extension UIImage {

    /// Create an image of the given `size` that's made of a single `color`.
    ///
    /// Size is in points.
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        let image = UIGraphicsImageRenderer(size: size).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }

        self.init(cgImage: image.cgImage!) // Force because there's no reason that the `cgImage` should be nil
    }
}
