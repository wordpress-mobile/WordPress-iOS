import Foundation


extension UIImage {
    convenience init?(contentsOfURL url: URL) {
        guard let rawImage = try? Data(contentsOf: url) else {
            return nil
        }

        self.init(data: rawImage)
    }

    func resizeWithMaximumSize(_ maximumSize: CGSize) -> UIImage {
        return resizedImage(with: .scaleAspectFit, bounds: maximumSize, interpolationQuality: .high)
    }

    func JPEGEncoded(_ quality: CGFloat = 0.8) -> Data? {
        return UIImageJPEGRepresentation(self, quality)
    }
}
