import Foundation


extension UIImage
{
    convenience init?(contentsOfURL url: NSURL) {
        guard let rawImage = NSData(contentsOfURL: url) else {
            return nil
        }

        self.init(data: rawImage)
    }

    func resizeWithMaximumSize(maximumSize: CGSize) -> UIImage {
        return resizedImageWithContentMode(.ScaleAspectFit, bounds: maximumSize, interpolationQuality: .High)
    }

    func JPEGEncoded(quality: CGFloat = 0.9) -> NSData? {
        return UIImageJPEGRepresentation(self, quality)
    }
}
