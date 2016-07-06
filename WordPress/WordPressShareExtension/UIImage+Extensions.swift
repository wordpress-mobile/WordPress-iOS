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
        let scale = UIScreen.mainScreen().scale
        let targetSize = CGSize(width: maximumSize.width * scale, height: maximumSize.height * scale)

        return resizedImageWithContentMode(.ScaleAspectFit, bounds: targetSize, interpolationQuality: .High)
    }
}
