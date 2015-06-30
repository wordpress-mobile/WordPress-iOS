import Foundation


extension UIView
{
    // MARK: - Public Methods
    public func pinSubview(subview: UIView, aboveSubview: UIView) {
        let constraint = NSLayoutConstraint(item: subview, attribute: .Bottom, relatedBy: .Equal, toItem: aboveSubview, attribute: .Top, multiplier: 1, constant: 0)
        addConstraint(constraint)
    }
    
    public func pinSubviewAtBottom(subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .Leading,  relatedBy: .Equal, toItem: subview, attribute: .Leading,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: subview, attribute: .Trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Bottom,   relatedBy: .Equal, toItem: subview, attribute: .Bottom,   multiplier: 1, constant: 0),
        ]
        
        addConstraints(newConstraints)
    }

    public func pinSubviewToAllEdges(subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .Leading,  relatedBy: .Equal, toItem: subview, attribute: .Leading,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: subview, attribute: .Trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Bottom,   relatedBy: .Equal, toItem: subview, attribute: .Bottom,   multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .Top,      relatedBy: .Equal, toItem: subview, attribute: .Top,      multiplier: 1, constant: 0)
        ]
        
        addConstraints(newConstraints)
    }
    
    public func constraintForAttribute(attribute: NSLayoutAttribute) -> CGFloat? {
        for constraint in constraints() as! [NSLayoutConstraint] {
            if constraint.firstItem as! NSObject == self {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    return constraint.constant
                }
            }
        }
        return nil
    }
    
    public func updateConstraint(attribute: NSLayoutAttribute, constant: CGFloat) {
        updateConstraintWithFirstItem(self, attribute: attribute, constant: constant)
    }

    public func updateConstraintWithFirstItem(firstItem: NSObject!, attribute: NSLayoutAttribute, constant: CGFloat) {
        for constraint in constraints() as! [NSLayoutConstraint] {
            if constraint.firstItem as! NSObject == firstItem {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    constraint.constant = constant
                }
            }
        }
    }
    
    public func updateConstraintWithFirstItem(firstItem: NSObject!, secondItem: NSObject!, firstItemAttribute: NSLayoutAttribute, secondItemAttribute: NSLayoutAttribute, constant: CGFloat) {
        for constraint in constraints() as! [NSLayoutConstraint] {
            if (constraint.firstItem as! NSObject == firstItem) && (constraint.secondItem as? NSObject == secondItem) {
                if constraint.firstAttribute == firstItemAttribute && constraint.secondAttribute == secondItemAttribute {
                    constraint.constant = constant
                }
            }
        }
    }
}
