import UIKit

public extension UIImage {

    @objc
    enum ScalingMode: Int32 {
        case scaleAspectFill
        case scaleAspectFit
    }

    @objc
    func resized (to size: CGSize, format: ScalingMode = .scaleAspectFit) -> UIImage {

        let horizontalRatio = size.width / self.size.width
        let verticalRatio = size.height / self.size.height

        let ratio: CGFloat

        switch format {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        }

        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)

        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = false

        return UIGraphicsImageRenderer(size: newSize, format: renderFormat).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
