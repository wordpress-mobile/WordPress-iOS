import UIKit

extension UIView {

    @objc func pinSubviewToAllEdges(_ subview: UIView,
                                    insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: subview.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
            ])
    }
}
