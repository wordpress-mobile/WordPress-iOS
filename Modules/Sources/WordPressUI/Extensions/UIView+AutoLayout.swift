import UIKit
import SwiftUI

extension UIView {
    /// Pins edges of the view to the edges of the given container. By default,
    /// pins to the nearest superview.
    @discardableResult
    public func pinEdges(
        _ edges: Edge.Set = .all,
        to container: AutoLayoutItem? = nil,
        insets: UIEdgeInsets = .zero,
        relation: AutoLayoutPinEdgesRelation = .equal,
        priority: UILayoutPriority? = nil
    ) -> [NSLayoutConstraint] {
        guard let container = container ?? superview else {
            assertionFailure("view has to be installed in the view hierarchy")
            return []
        }
        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []

        func pin(_ edge: Edge.Set, _ closure: @autoclosure () -> NSLayoutConstraint) {
            guard edges.contains(edge) else {
                return
            }
            let constraint = closure()
            if let priority {
                constraint.priority = priority
            }
            constraints.append(constraint)
        }

        switch relation {
        case .equal:
            pin(.top, topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top))
            pin(.trailing, trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right))
            pin(.bottom, bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom))
            pin(.leading, leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left))
        case .lessThanOrEqual:
            pin(.top, topAnchor.constraint(lessThanOrEqualTo: container.topAnchor, constant: insets.top))
            pin(.trailing, trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -insets.right))
            pin(.bottom, bottomAnchor.constraint(greaterThanOrEqualTo: container.bottomAnchor, constant: -insets.bottom))
            pin(.leading, leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: insets.left))
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
