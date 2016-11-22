import Foundation

extension UIImage
{
    func imageWithTintColor(color: UIColor) -> UIImage? {
        guard let cgImg = CGImage else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        let bounds = CGRect(origin: CGPointZero, size: size)

        let flipTransform = CGAffineTransformMake(1, 0, 0, -1, 0, size.height)
        CGContextConcatCTM(context, flipTransform)

        CGContextClipToMask(context, bounds, cgImg)

        color.setFill()
        CGContextFillRect(context, bounds)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage
    }
}
