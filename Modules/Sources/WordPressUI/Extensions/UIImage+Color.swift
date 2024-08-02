import UIKit

public extension UIImage {

    static func from(color: UIColor, havingSize size: CGSize = CGSize(width: 1.0, height: 1.0)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
