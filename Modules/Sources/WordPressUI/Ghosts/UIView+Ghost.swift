import Foundation
import UIKit

// MARK: - Ghost Animations API
//
extension UIView {

    /// Property that defines if a view is ghostable. Defaults set to true.
    ///
    public var isGhostableDisabled: Bool {
        get {
            return objc_getAssociatedObject(self, &Keys.isGhostable) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &Keys.isGhostable, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// Applies Ghost Layers and starts the Beating Animation.
    ///
    public func startGhostAnimation(style: GhostStyle = .default) {
        insertGhostLayers { layer in
            layer.startAnimating(fromColor: style.beatStartColor, toColor: style.beatEndColor, duration: style.beatDuration)
        }
    }

    /// Loops thru all of the Ghost Layers (that are already there) and restarts the Beating Animation.
    /// If there were no previous Ghost Layers inserted, this method won't do anything.
    ///
    public func restartGhostAnimation(style: GhostStyle = .default) {
        enumerateGhostLayers { layer in
            layer.startAnimating(fromColor: style.beatStartColor, toColor: style.beatEndColor, duration: style.beatDuration)
        }
    }

    /// Removes the Ghost Layers.
    ///
    public func stopGhostAnimation() {
        enumerateGhostLayers { layer in
            layer.removeFromSuperlayer()
        }
    }
}

// MARK: - Nested Types
//
private extension UIView {

    enum Keys {
        static var isGhostable = 0x1000
    }
}
