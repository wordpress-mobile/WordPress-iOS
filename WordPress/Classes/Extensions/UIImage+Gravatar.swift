import Foundation
import UIKit

extension UIImage {

    func gravatarIcon(size: CGFloat) -> UIImage? {
        resized(to: CGSize(width: size, height: size))
            .cropToCircle()
            .withRenderingMode(.alwaysOriginal)
    }

    func cropToCircle() -> UIImage {
        let imageWidth = size.width
        let imageHeight = size.height

        let diameter = min(imageWidth, imageHeight)
        let isLandscape = imageWidth > imageHeight

        let xOffset = isLandscape ? (imageWidth - diameter) / 2 : 0
        let yOffset = isLandscape ? 0 : (imageHeight - diameter) / 2

        let imageSize = CGSize(width: diameter, height: diameter)

        return UIGraphicsImageRenderer(size: imageSize).image { _ in
            let ovalPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: imageSize))
            ovalPath.addClip()
            draw(at: CGPoint(x: -xOffset, y: -yOffset))
        }
    }

    func withAlpha(_ alpha: CGFloat) -> UIImage {
        let imageWithAlpha = UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { _ in
            draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: alpha)
        }
        return imageWithAlpha.withRenderingMode(.alwaysOriginal)
    }

    /// Returns the image centered on a transparent canvas of the given size.
    func padded(to canvasSize: CGSize) -> UIImage {
        let origin = CGPoint(
            x: (canvasSize.width - size.width) / 2,
            y: (canvasSize.height - size.height) / 2
        )
        let image = UIGraphicsImageRenderer(size: canvasSize, format: imageRendererFormat).image { _ in
            draw(at: origin)
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
}
