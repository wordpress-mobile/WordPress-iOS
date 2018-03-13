import Foundation


// MARK: - UIView Helpers
//
extension UIView {

    @objc public func pinSubviewAtCenter(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: subview, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: subview, attribute: .centerY, multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    @objc public func pinSubviewToAllEdges(_ subview: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: subview.leadingAnchor),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor),
            topAnchor.constraint(equalTo: subview.topAnchor),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            ])
    }

    @objc public func pinSubviewToAllEdgeMargins(_ subview: UIView) {
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: subview.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: subview.trailingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: subview.topAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            ])
    }

    @objc public func findFirstResponder() -> UIView? {
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

    @objc public func userInterfaceLayoutDirection() -> UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
    }
}
