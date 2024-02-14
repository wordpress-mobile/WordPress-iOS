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
            contentView.pinSubviewToAllEdges(swiftUICellViewController.view)

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellViewController.view.layoutIfNeeded()
        }

        self.controller?.view.invalidateIntrinsicContentSize()
    }
}
