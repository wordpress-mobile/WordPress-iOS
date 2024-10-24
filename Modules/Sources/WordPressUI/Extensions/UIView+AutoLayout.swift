import UIKit
import SwiftUI

extension UIView {
    /// Pins edges of the view to the edges of the given target view or layout
    /// guide. By default, pins to the superview.
    ///
    /// The view also gets enabled for Auto Layout by setting
    /// `translatesAutoresizingMaskIntoConstraints` to `false`.
    ///
    /// Example uage:
    ///
    /// ```swift
    /// subview.pinEdges() // to superview
    /// subview.pinEdges(to: superview.safeAreaLayoutGuide)
    /// ```
    @discardableResult
    public func pinEdges(
        _ edges: Edge.Set = .all,
        to target: AutoLayoutItem? = nil,
        insets: UIEdgeInsets = .zero,
        relation: AutoLayoutPinEdgesRelation = .equal,
        priority: UILayoutPriority? = nil
    ) -> [NSLayoutConstraint] {
        guard let target = target ?? superview else {
            assertionFailure("view has to be installed in the view hierarchy")
            return []
        }
        translatesAutoresizingMaskIntoConstraints = false

#if DEBUG
        if let target = target as? UIView {
            assert(!target.isDescendant(of: self), "The target view can't be a descendant for the view")
        }
#endif

        var constraints: [NSLayoutConstraint] = []

        func pin(_ edge: Edge.Set, _ closure: @autoclosure () -> NSLayoutConstraint) {
            guard edges.contains(edge) else { return }
            constraints.append(closure())
        }

        switch relation {
        case .equal:
            pin(.top, topAnchor.constraint(equalTo: target.topAnchor, constant: insets.top))
            pin(.trailing, trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -insets.right))
            pin(.bottom, bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -insets.bottom))
            pin(.leading, leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: insets.left))
        case .lessThanOrEqual:
            pin(.top, topAnchor.constraint(greaterThanOrEqualTo: target.topAnchor, constant: insets.top))
            pin(.trailing, trailingAnchor.constraint(lessThanOrEqualTo: target.trailingAnchor, constant: -insets.right))
            pin(.bottom, bottomAnchor.constraint(lessThanOrEqualTo: target.bottomAnchor, constant: -insets.bottom))
            pin(.leading, leadingAnchor.constraint(greaterThanOrEqualTo: target.leadingAnchor, constant: insets.left))
        }

        if let priority {
            for constraint in constraints {
                constraint.priority = priority
            }
        }

        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Pins the view to the center of the given container. By default,
    /// pins to the superview.
    @discardableResult
    public func pinCenter(
        to target: AutoLayoutItem? = nil,
        offset: UIOffset = .zero,
        priority: UILayoutPriority? = nil
    ) -> [NSLayoutConstraint] {
        guard let target = target ?? superview else {
            assertionFailure("view has to be installed in the view hierarchy")
            return []
        }
        translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            centerXAnchor.constraint(equalTo: target.centerXAnchor, constant: offset.horizontal),
            centerYAnchor.constraint(equalTo: target.centerYAnchor, constant: offset.vertical),
        ]

        if let priority {
            for constraint in constraints {
                constraint.priority = priority
            }
        }

        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}

public protocol AutoLayoutItem {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

public enum AutoLayoutPinEdgesRelation {
    case equal
    case lessThanOrEqual
}

extension UIView: AutoLayoutItem {}
extension UILayoutGuide: AutoLayoutItem {}
