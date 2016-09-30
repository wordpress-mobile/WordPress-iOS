import Foundation


// MARK: - CGAffineTransform Helpers
//
extension CGAffineTransform
{
    /// Returns a CGAffineTransform cotaining both, a Rotation + Scale transform, with the specified
    /// parameters.
    ///
    static func makeRotation(angle: CGFloat, scale: CGFloat) -> CGAffineTransform {
        let angle   = angle * CGFloat(M_PI) / 180.0
        let rotate  = CGAffineTransformMakeRotation(angle)
        let scale   = CGAffineTransformMakeScale(scale, scale)

        return CGAffineTransformConcat(rotate, scale)
    }
}
