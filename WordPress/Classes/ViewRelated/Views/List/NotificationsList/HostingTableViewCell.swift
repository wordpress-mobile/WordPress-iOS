import UIKit
import SwiftUI

class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?

    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        } else {
            let swiftUICellViewController = UIHostingController(rootView: view)
            controller = swiftUICellViewController
            swiftUICellViewController.view.backgroundColor = .clear

            layoutIfNeeded()

            parent.addChild(swiftUICellViewController)
            contentView.addSubview(swiftUICellViewController.view)
            swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraint(
                NSLayoutConstraint(
                    item: swiftUICellViewController.view!,
                    attribute: NSLayoutConstraint.Attribute.leading,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: contentView,
                    attribute: NSLayoutConstraint.Attribute.leading,
                    multiplier: 1.0,
                    constant: 0.0
                )
            )
            contentView.addConstraint(
                NSLayoutConstraint(
                    item: swiftUICellViewController.view!,
                    attribute: NSLayoutConstraint.Attribute.trailing,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: contentView,
                    attribute: NSLayoutConstraint.Attribute.trailing,
                    multiplier: 1.0,
                    constant: 0.0
                )
            )
            contentView.addConstraint(
                NSLayoutConstraint(
                    item: swiftUICellViewController.view!,
                    attribute: NSLayoutConstraint.Attribute.top,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: contentView,
                    attribute: NSLayoutConstraint.Attribute.top,
                    multiplier: 1.0,
                    constant: 0.0
                )
            )
            contentView.addConstraint(
                NSLayoutConstraint(
                    item: swiftUICellViewController.view!,
                    attribute: NSLayoutConstraint.Attribute.bottom,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: contentView,
                    attribute: NSLayoutConstraint.Attribute.bottom,
                    multiplier: 1.0,
                    constant: 0.0
                )
            )

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellViewController.view.layoutIfNeeded()
        }
    }
}
