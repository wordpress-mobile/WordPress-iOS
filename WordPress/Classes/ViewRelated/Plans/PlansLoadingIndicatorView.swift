import UIKit
import WordPressShared

// Circle View is 100x100 pixels
private struct Config {
    // Icon images are 256 pixels high
    struct Scale {
        static let free: CGFloat = 0.25
        static let premium: CGFloat = 0.35
        static let business: CGFloat = 0.3
    }

    // Distance from view center
    struct OffsetX {
        static let free: CGFloat     = -20
        static let premium: CGFloat  = 0
        static let business: CGFloat = 20
    }

    // Final vertical offset from the center
    struct OffsetY {
        static let free: CGFloat     = 30
        static let premium: CGFloat  = 12
        static let business: CGFloat = 25
    }

    // Initial vertical offset from bottom of the circle view's bounding box
    struct InitialOffsetY {
        static let free: CGFloat     = 0
        static let premium: CGFloat  = 0
        static let business: CGFloat = 0
    }

    // The total duration of the animations, measured in seconds
    struct Duration {
        // Make this larger than 1 to slow down all animations
        static let durationScale: TimeInterval = 1.2
        static let free: TimeInterval     = 1.4
        static let premium: TimeInterval  = 1
        static let business: TimeInterval = 1.2
    }

    // The amount of time (measured in seconds) to wait before beginning the animations
    struct Delay {
        static let initial: TimeInterval  = 0.3
        static let free: TimeInterval     = 0.35
        static let premium: TimeInterval  = 0.0
        static let business: TimeInterval = 0.2
    }

    // The damping ratio for the spring animation as it approaches its quiescent state.
    // To smoothly decelerate the animation without oscillation, use a value of 1. Employ a damping ratio closer to zero to increase oscillation.
    struct SpringDamping {
        static let free: CGFloat     = 0.5
        static let premium: CGFloat  = 0.65
        static let business: CGFloat = 0.5
    }

    // The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment.
    // A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
    struct InitialSpringVelocity {
        static let free: CGFloat     = 0.1
        static let premium: CGFloat  = 0.01
        static let business: CGFloat = 0.1
    }

    struct DefaultSize {
        static let width: CGFloat    = 100
        static let height: CGFloat   = 100
    }
}


// ===========================================================================


private extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init()
        self.origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        self.size = size
    }
}

private extension CGSize {
    func scaleBy(_ scale: CGFloat) -> CGSize {
        return self.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

private extension UIView {
    var boundsCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

class PlansLoadingIndicatorView: UIView {
    fileprivate let freeView = UIImageView(image: UIImage(named: "plan-free-loading")!)
    fileprivate let premiumView = UIImageView(image: UIImage(named: "plan-premium-loading")!)
    fileprivate let businessView = UIImageView(image: UIImage(named: "plan-business-loading")!)
    fileprivate let circleView = UIView()

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: Config.DefaultSize.width, height: Config.DefaultSize.height))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .neutral(.shade5)
        circleView.clipsToBounds = true
        circleView.addSubview(premiumView)
        circleView.addSubview(freeView)
        circleView.addSubview(businessView)
        addSubview(circleView)

        freeView.frame = targetFreeFrame
        premiumView.frame = targetPremiumFrame
        businessView.frame = targetBusinessFrame

        circleView.backgroundColor = UIColor(red: 211/255, green: 222/255, blue: 230/255, alpha: 1)
        circleView.layer.cornerRadius = 50
        setInitialPositions()
    }

    fileprivate var targetFreeFrame: CGRect {
        let freeCenter = boundsCenter.applying(CGAffineTransform(translationX: Config.OffsetX.free, y: Config.OffsetY.free))
        let freeSize = freeView.sizeThatFits(bounds.size).scaleBy(Config.Scale.free)
        return CGRect(center: freeCenter, size: freeSize)
    }

    fileprivate var targetPremiumFrame: CGRect {
        let premiumCenter = boundsCenter.applying(CGAffineTransform(translationX: Config.OffsetX.premium, y: Config.OffsetY.premium))
        let premiumSize = premiumView.sizeThatFits(bounds.size).scaleBy(Config.Scale.premium)
        return CGRect(center: premiumCenter, size: premiumSize)
    }

    fileprivate var targetBusinessFrame: CGRect {
        let businessCenter = boundsCenter.applying(CGAffineTransform(translationX: Config.OffsetX.business, y: Config.OffsetY.business))
        let businessSize = businessView.sizeThatFits(bounds.size).scaleBy(Config.Scale.business)
        return CGRect(center: businessCenter, size: businessSize)
    }

    fileprivate func setInitialPositions() {
        let freeOffset = Config.InitialOffsetY.free + bounds.size.height - targetFreeFrame.origin.y
        freeView.transform = CGAffineTransform(translationX: 0, y: freeOffset)
        let premiumOffset = Config.InitialOffsetY.premium + bounds.size.height - targetPremiumFrame.origin.y
        premiumView.transform = CGAffineTransform(translationX: 0, y: premiumOffset)
        let businessOffset = Config.InitialOffsetY.business + bounds.size.height - targetBusinessFrame.origin.y
        businessView.transform = CGAffineTransform(translationX: 0, y: businessOffset)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = min(bounds.width, bounds.height)
        circleView.frame = CGRect(center: boundsCenter, size: CGSize(width: size, height: size))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        animateAfterDelay(Config.Delay.initial)
    }

    @objc func animateAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { [weak self] in self?.animate() }
        )
    }

    @objc func animate() {
        UIView.performWithoutAnimation {
            self.setInitialPositions()
        }
        UIView.animate(
            withDuration: Config.Duration.free * Config.Duration.durationScale,
            delay: Config.Delay.free * Config.Duration.durationScale,
            usingSpringWithDamping: Config.SpringDamping.free,
            initialSpringVelocity: Config.InitialSpringVelocity.free,
            options: .curveEaseOut,
            animations: { [unowned freeView] in
                freeView.transform = CGAffineTransform.identity
            })

        UIView.animate(
            withDuration: Config.Duration.premium * Config.Duration.durationScale,
            delay: Config.Delay.premium * Config.Duration.durationScale,
            usingSpringWithDamping: Config.SpringDamping.premium,
            initialSpringVelocity: Config.InitialSpringVelocity.premium,
            options: .curveEaseOut,
            animations: { [unowned premiumView] in
                premiumView.transform = CGAffineTransform.identity
            })

        UIView.animate(
            withDuration: Config.Duration.business * Config.Duration.durationScale,
            delay: Config.Delay.business * Config.Duration.durationScale,
            usingSpringWithDamping: Config.SpringDamping.business,
            initialSpringVelocity: Config.InitialSpringVelocity.business,
            options: .curveEaseOut,
            animations: { [unowned businessView] in
                businessView.transform = CGAffineTransform.identity
            })
    }
}
