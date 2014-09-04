import Foundation


extension UIView
{
    public func constraintForAttribute(attribute: NSLayoutAttribute) -> CGFloat? {
        for constraint in constraints() as [NSLayoutConstraint] {
            if constraint.firstItem as NSObject == self {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    return constraint.constant
                }
            }
        }
        return nil
    }

    public func updateConstraint(attribute: NSLayoutAttribute, constant: CGFloat) {
        updateConstraintForView(self, attribute: attribute, constant: constant)
    }

    public func updateConstraintForView(fistItem: NSObject!, attribute: NSLayoutAttribute, constant: CGFloat) {
        for constraint in constraints() as [NSLayoutConstraint] {
            if constraint.firstItem as NSObject == fistItem {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    constraint.constant = constant
                }
            }
        }
    }
}
