import UIKit

public extension UIImage {

    @objc
    enum ScalingMode: Int32 {
        case scaleAspectFill
        case scaleAspectFit
    }

    @objc
    func resized(to newSize: CGSize, format: ScalingMode = .scaleAspectFit) -> UIImage {
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = false

        return UIGraphicsImageRenderer(size: newSize, format: renderFormat).image { context in
            context.cgContext.concatenate(transform(forSuggestedSize: newSize))
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func dimensions(forSuggestedSize newSize: CGSize, format: ScalingMode = .scaleAspectFit) -> CGSize {
        let imageSize = self.size
        let aspectWidth = newSize.width / imageSize.width
        let aspectHeight = newSize.height / imageSize.height
        var scaleFactor: CGFloat

        switch format {
        case .scaleAspectFit:
            scaleFactor = min(aspectWidth, aspectHeight)
        case .scaleAspectFill:
            scaleFactor = max(aspectWidth, aspectHeight)
        }

        return CGSize(
            width: (imageSize.width * scaleFactor).rounded(.toNearestOrEven),
            height: (imageSize.height * scaleFactor).rounded(.toNearestOrEven)
        )
    }

    func transform(forSuggestedSize newSize: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransformIdentity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height)
            transform = CGAffineTransformRotate(transform, .pi)
        case .left, .leftMirrored:
            transform = CGAffineTransformTranslate(transform, newSize.width, 0)
            transform = CGAffineTransformRotate(transform, .pi / 2)
        case .right, .rightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, newSize.height)
            transform = CGAffineTransformRotate(transform, .pi / -2)
        default:
            break // Do nothing – the image is already using the right orientation
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = CGAffineTransformTranslate(transform, newSize.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        case .leftMirrored, .rightMirrored:
            transform = CGAffineTransformTranslate(transform, newSize.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default:
            break // Do nothing
        }

        return transform
    }
}
