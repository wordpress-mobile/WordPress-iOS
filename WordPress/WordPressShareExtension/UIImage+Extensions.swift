import Foundation
import ImageIO

extension UIImage {
    convenience init?(contentsOfURL url: URL) {
        guard let rawImage = try? Data(contentsOf: url) else {
            return nil
        }

        self.init(data: rawImage)
    }

    func resizeWithMaximumSize(_ maximumSize: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumSize,
        ]

        guard let imageData = pngData() as CFData?,
              let imageSource = CGImageSourceCreateWithData(imageData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) else {

            return nil
        }

        return UIImage(cgImage: image)
    }

    func JPEGEncoded(_ quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
}
