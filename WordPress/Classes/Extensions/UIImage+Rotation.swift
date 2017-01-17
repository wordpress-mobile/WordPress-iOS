import Foundation

extension UIImage {
    func rotate180Degrees() -> UIImage? {
        guard let cgImg = cgImage else {
            return nil
        }
        return UIImage(cgImage: cgImg, scale: scale, orientation: .down)
    }
}
