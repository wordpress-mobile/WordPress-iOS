import Foundation
import QuartzCore
import UIKit

/// GhostLayer: Can be inserted into a UIView instance, and reacts to its resize events.
///
class GhostLayer: CALayer {

    /// KVO Reference Token
    ///
    private var observerToken: NSKeyValueObservation?

    /// Required Initializer
    ///
    override init(layer: Any) {
        super.init(layer: layer)
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    /// Designated Initializer
    ///
    override init() {
        super.init()
        anchorPoint = .zero
    }

    /// Inserts the receiver into the target view's Layer Hierarchy.
    ///
    func insert(into view: UIView) {
        view.layer.insertSublayer(self, at: .max)
        startObservingBoundEvents(on: view )
    }

    /// Removes the receiver from the current suberlayer (if any).
    ///
    override func removeFromSuperlayer() {
        super.removeFromSuperlayer()
        observerToken = nil
    }
}

/// Private Methods
///
private extension GhostLayer {

    /// Starts listening for Bounds Changes on the specified UIView instance.
    ///
    func startObservingBoundEvents(on container: UIView) {
        observerToken = container.observe(\.bounds, options: .initial) { [weak self] (view, _) in
            self?.bounds = view.bounds
        }
    }
}

/// Animations API
///
extension GhostLayer {

    /// Applies a GhostAnimation.
    ///
    func startAnimating(fromColor: UIColor, toColor: UIColor, duration: TimeInterval) {
        let animation = GhostAnimation(startColor: fromColor, endColor: toColor, loopDuration: duration)
        add(animation, forKey: GhostAnimation.defaultKey)
    }

    /// Removes the GhostAnimation (if any).
    ///
    func stopAnimating() {
        removeAnimation(forKey: GhostAnimation.defaultKey)
    }

    /// Indicates if the receiver has an active GhostAnimation.
    ///
    var isAnimating: Bool {
        return animation(forKey: GhostAnimation.defaultKey) != nil
    }
}
