import Foundation

extension UIImage {
    public func imageWithTintColor(_ color: UIColor) -> UIImage? {
        guard let cgImg = cgImage else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        let bounds = CGRect(origin: CGPoint.zero, size: size)

        let flipTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        context.concatenate(flipTransform)

        context.clip(to: bounds, mask: cgImg)

        color.setFill()
        context.fill(bounds)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage
    }
}
