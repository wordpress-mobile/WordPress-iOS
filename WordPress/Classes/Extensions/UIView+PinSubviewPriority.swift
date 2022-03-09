import Foundation
import UIKit

extension UIView {
    /// Adds constraints that pin a subview to self with padding insets and an applied priority.
    ///
    /// - Parameters:
    ///   - subview: a subview to be pinned to self.
    ///   - insets: spacing between each subview edge to self. A positive value for an edge indicates that the subview is inside self on that edge.
    ///   - priority: the `UILayoutPriority` to be used for the constraints
    @objc public func pinSubviewToAllEdges(_ subview: UIView, insets: UIEdgeInsets = .zero, priority: UILayoutPriority = .defaultHigh) {
        let constraints = [
            leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: -insets.left),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: subview.topAnchor, constant: -insets.top),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
        ]

        constraints.forEach { $0.priority = priority }

        NSLayoutConstraint.activate(constraints)
    }
}
