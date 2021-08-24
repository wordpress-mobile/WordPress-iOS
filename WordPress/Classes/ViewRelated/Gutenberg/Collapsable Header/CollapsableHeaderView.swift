import UIKit

class CollapsableHeaderView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event),
              result.isUserInteractionEnabled,
              result != self // Ignore touches for self but accept them for the accessory view
              else {
            return nil
        }

        return result
    }
}
