import Foundation

extension UIImage
{
    func rotate180Degrees() -> UIImage? {
        guard let cgImg = CGImage else {
            return nil
        }

        return UIImage(CGImage: cgImg, scale: scale, orientation: .Down)
    }
}
