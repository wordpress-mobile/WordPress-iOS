import Foundation
import UIKit

extension UIImage {
    // Adapted from https://gist.github.com/mxcl/76f40027b1ef515e4e6b41292b54fe92
    func blur(radius: Float) -> UIImage? {
        let ciContext = CIContext(options: nil)

        guard
            let cgImage = self.cgImage,
            let ciFilter = CIFilter(name: "CIGaussianBlur")
        else {
            return self
        }

        let inputImage = CIImage(cgImage: cgImage)

        ciFilter.setValue(inputImage, forKey: kCIInputImageKey)
        ciFilter.setValue(radius, forKey: "inputRadius")

        guard
            let resultImage = ciFilter.value(forKey: kCIOutputImageKey) as? CIImage,
            let outputImage = ciContext.createCGImage(resultImage, from: inputImage.extent)
        else {
            return self
        }

        return UIImage(cgImage: outputImage)
    }
}

// MARK: - WordPress Named Assets
//
@objc
public extension UIImage {
    static var siteIconPlaceholder: UIImage {
        return UIImage(named: "blavatar-default")!
    }
}
