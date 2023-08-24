import Foundation
import UIKit

extension UIImage {

    func gravatarIcon() -> UIImage? {
        let iconDimension = 24.0
        let iconSize = CGSize(width: iconDimension, height: iconDimension)
        let resizedImage = self.resizedImage(iconSize, interpolationQuality: .default)
        return resizedImage?.cropToCircle().withRenderingMode(.alwaysOriginal)
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
}
