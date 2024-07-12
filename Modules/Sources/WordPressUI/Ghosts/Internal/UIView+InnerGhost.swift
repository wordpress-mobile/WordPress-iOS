import Foundation
import UIKit

/// UIView: Skeletonizer Public API
///
extension UIView {

    /// Applies a GhostLayer on each one of the receiver's Leaf Views (if needed).
    ///
    func insertGhostLayers(callback: (GhostLayer) -> Void) {
        layoutIfNeeded()

        enumerateGhostableLeafViews { leafView in
            guard leafView.containsGhostLayer == false else {
                return
            }

            let layer = GhostLayer()
            layer.insert(into: leafView)
            callback(layer)
        }
    }

    /// Removes all of the GhostLayer(s) from the Leaf Views.
    ///
    func removeGhostLayers() {
        enumerateGhostLayers { skeletonLayer in
            skeletonLayer.removeFromSuperlayer()
        }
    }

    /// Enumerates all of the receiver's GhostLayer(s).
    ///
    func enumerateGhostLayers(callback: (GhostLayer) -> Void) {
        enumerateGhostableLeafViews { leafView in
            let targetLayer = leafView.layer.sublayers?.first(where: { $0 is GhostLayer })
            guard let skeletonLayer = targetLayer as? GhostLayer else {
                return
            }

            callback(skeletonLayer)
        }
    }
}

/// Private Methods
///
private extension UIView {

    /// Indicates if the receiver contains a GhostLayer.
    ///
    var containsGhostLayer: Bool {
        let output = layer.sublayers?.contains { $0 is GhostLayer }
        return output ?? false
    }

    /// Indicates if the receiver's classname starts with an underscore (UIKit's internals).
    ///
    var isPrivateUIKitInstance: Bool {
        let classnameWithoutNamespaces = NSStringFromClass(type(of: self)).components(separatedBy: ".").last
        return classnameWithoutNamespaces?.starts(with: "_") ?? false
    }

    /// Enumerates all of the receiver's Leaf Views.
    ///
    func enumerateGhostableLeafViews(callback: (UIView) -> Void) {
        guard !isGhostableDisabled && !isPrivateUIKitInstance else {
            return
        }

        if subviews.isEmpty {
            callback(self)
        } else {
            for subview in subviews {
                subview.enumerateGhostableLeafViews(callback: callback)
            }
        }
    }
}
