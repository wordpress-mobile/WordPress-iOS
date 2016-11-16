import Foundation


extension UIView
{
    // MARK: - Public Methods
    public func pinSubview(_ subview: UIView, aboveSubview: UIView) {
        let constraint = NSLayoutConstraint(item: subview, attribute: .bottom, relatedBy: .equal, toItem: aboveSubview, attribute: .top, multiplier: 1, constant: 0)
        addConstraint(constraint)
    }

    public func pinSubviewAtBottom(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .leading,  relatedBy: .equal, toItem: subview, attribute: .leading,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: subview, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom,   relatedBy: .equal, toItem: subview, attribute: .bottom,   multiplier: 1, constant: 0),
        ]

        addConstraints(newConstraints)
    }

    public func pinSubviewAtCenter(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .centerX,  relatedBy: .equal, toItem: subview, attribute: .centerX,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY,  relatedBy: .equal, toItem: subview, attribute: .centerY,  multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    public func pinSubviewToAllEdges(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .leading,  relatedBy: .equal, toItem: subview, attribute: .leading,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: subview, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom,   relatedBy: .equal, toItem: subview, attribute: .bottom,   multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top,      relatedBy: .equal, toItem: subview, attribute: .top,      multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    public func pinSubviewToAllEdgeMargins(_ subview: UIView) {
        subview.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }

    public func constraintForAttribute(_ attribute: NSLayoutAttribute) -> CGFloat? {
        for constraint in constraints {
            if constraint.firstItem as! NSObject == self {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    return constraint.constant
                }
            }
        }
        return nil
    }

    public func updateConstraint(_ attribute: NSLayoutAttribute, constant: CGFloat) {
        updateConstraintWithFirstItem(self, attribute: attribute, constant: constant)
    }

    public func updateConstraintWithFirstItem(_ firstItem: NSObject!, attribute: NSLayoutAttribute, constant: CGFloat) {
        for constraint in constraints {
            if constraint.firstItem as! NSObject == firstItem {
                if constraint.firstAttribute == attribute || constraint.secondAttribute == attribute {
                    constraint.constant = constant
                }
            }
        }
    }

    public func updateConstraintWithFirstItem(_ firstItem: NSObject!, secondItem: NSObject!, firstItemAttribute: NSLayoutAttribute, secondItemAttribute: NSLayoutAttribute, constant: CGFloat) {
        for constraint in constraints {
            if (constraint.firstItem as! NSObject == firstItem) && (constraint.secondItem as? NSObject == secondItem) {
                if constraint.firstAttribute == firstItemAttribute && constraint.secondAttribute == secondItemAttribute {
                    constraint.constant = constant
                }
            }
        }
    }
}
