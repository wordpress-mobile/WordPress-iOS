import Foundation


extension UIImage
{
    convenience init?(contentsOfURL url: NSURL) {
        guard let rawImage = NSData(contentsOfURL: url) else {
            return nil
        }

        self.init(data: rawImage)
    }
}
