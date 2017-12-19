class PluginListCell: WPTableViewCellSubtitle {
    private let updateImageView = UIImageView(image: #imageLiteral(resourceName: "gridicon-sync-circled"))
    private let spinningAnimationKey = "spinning"

    var updateImageVisible: Bool {
        get {
            return accessoryView == updateImageView
        }
        set {
            accessoryView = newValue ? updateImageView : nil
        }
    }

    var updateImageAnimating: Bool {
        get {
            return updateImageView.layer.animation(forKey: spinningAnimationKey) != nil
        }
        set {
            guard updateImageAnimating != newValue else {
                return
            }
            if newValue {
                updateImageView.layer.add(spinningAnimation, forKey: spinningAnimationKey)
            } else {
                updateImageView.layer.removeAnimation(forKey: spinningAnimationKey)
            }
        }
    }

    private var spinningAnimation: CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.fromValue = 0.0
        animation.toValue = Float(Float.pi * 2.0)
        return animation
    }
}
