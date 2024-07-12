import Foundation
import QuartzCore
import UIKit

/// GhostAnimation: Animates a CALayer with a "Beating" animation, that interpolates from Color A to Color B.
///
class GhostAnimation: CABasicAnimation {

    /// Default Animation Key
    ///
    static let defaultKey = "SkeletonAnimationKey"

    /// Designated Initializer
    ///
    convenience init(startColor: UIColor, endColor: UIColor, loopDuration: TimeInterval) {
        self.init()

        fromValue = startColor.cgColor
        toValue = endColor.cgColor
        duration = loopDuration
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    /// Required Initializer
    ///
    override init() {
        super.init()

        keyPath = #keyPath(CALayer.backgroundColor)
        timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        repeatCount = .infinity
        autoreverses = true
    }

    /// NSCopying Conformance
    ///
    override func copy(with zone: NSZone? = nil) -> Any {
        let theCopy = GhostAnimation()
        theCopy.fromValue = fromValue
        theCopy.toValue = toValue
        theCopy.duration = duration
        return theCopy
    }
}
