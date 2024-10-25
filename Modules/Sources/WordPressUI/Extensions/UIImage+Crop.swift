import UIKit

// MARK: - UIImage + Crop Method
//
extension UIImage {

    /// This method crops an image to the specified rect
    ///
    public func cropping(to rect: CGRect) -> UIImage {
        // Correct rect size based on the device screen scale
        let scaledRect = CGRect(x: rect.origin.x * self.scale,
                                y: rect.origin.y * self.scale,
                                width: rect.size.width * self.scale,
                                height: rect.size.height * self.scale)

        if let croppedImage = self.cgImage?.cropping(to: scaledRect) {
            return UIImage(cgImage: croppedImage, scale: self.scale, orientation: self.imageOrientation)
        }
        return self
    }

    /// Crops the image in a perfectly square size. Longer edge is cropped out.
    /// If the image is already square, then just returns `self`.
    public func squared() -> UIImage {
        let currentSizeInPixels: CGSize = .init(width: size.width * scale, height: size.height * scale)
        guard currentSizeInPixels.width != currentSizeInPixels.height else { return self }
        let squareEdge = floor(min(currentSizeInPixels.width, currentSizeInPixels.height))
        let newSize = CGSize(width: squareEdge, height: squareEdge)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let squareImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return squareImage
    }
}
