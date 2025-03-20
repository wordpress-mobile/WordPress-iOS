import UIKit

public extension UIImage {

    /// Create an image of the given `size` that's made of a single `color`.
    ///
    /// - parameter size: Size in points.
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: .up)
        } else {
            assertionFailure("faield to render image with color")
            self.init()
        }
    }
}
