import Foundation


// MARK: - UIView Helpers
//
extension UIView {

    func pinSubviewAtCenter(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .centerX,  relatedBy: .equal, toItem: subview, attribute: .centerX,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY,  relatedBy: .equal, toItem: subview, attribute: .centerY,  multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    func pinSubviewToAllEdges(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .leading,  relatedBy: .equal, toItem: subview, attribute: .leading,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: subview, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom,   relatedBy: .equal, toItem: subview, attribute: .bottom,   multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top,      relatedBy: .equal, toItem: subview, attribute: .top,      multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    func pinSubviewToAllEdgeMargins(_ subview: UIView) {
        subview.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }

    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }

        for subview in subviews {
            guard let responder = subview.findFirstResponder() else {
                continue
            }

            return responder
        }

        return nil
    }

    func userInterfaceLayoutDirection() -> UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }
}
