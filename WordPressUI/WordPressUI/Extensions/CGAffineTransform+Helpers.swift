import Foundation


// MARK: - CGAffineTransform Helpers
//
extension CGAffineTransform {
    /// Returns a CGAffineTransform cotaining both, a Rotation + Scale transform, with the specified
    /// parameters.
    ///
    public static func makeRotation(_ angle: CGFloat, scale: CGFloat) -> CGAffineTransform {
        let angle   = angle * CGFloat.pi / 180.0
        let rotate  = CGAffineTransform(rotationAngle: angle)
        let scale   = CGAffineTransform(scaleX: scale, y: scale)

        return rotate.concatenating(scale)
    }
}
