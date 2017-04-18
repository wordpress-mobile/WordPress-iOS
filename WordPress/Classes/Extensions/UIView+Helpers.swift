import Foundation

protocol EdgeAnchorProvider {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: EdgeAnchorProvider {}
extension UILayoutGuide: EdgeAnchorProvider {}

// MARK: - UIView Helpers
//
extension UIView {
    func pinSubview(_ subview: UIView, horizontalEdges edges: EdgeAnchorProvider) {
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: edges.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: edges.trailingAnchor)
            ])
    }

    func pinSubview(_ subview: UIView, verticalEdges edges: EdgeAnchorProvider) {
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: edges.topAnchor),
            subview.bottomAnchor.constraint(equalTo: edges.bottomAnchor),
            ])
    }

    func pinSubview(_ subview: UIView, edges: EdgeAnchorProvider) {
        pinSubview(subview, verticalEdges: edges)
        pinSubview(subview, horizontalEdges: edges)
    }

    func pinSubviewAtCenter(_ subview: UIView) {
        let newConstraints = [
            NSLayoutConstraint(item: self, attribute: .centerX,  relatedBy: .equal, toItem: subview, attribute: .centerX,  multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY,  relatedBy: .equal, toItem: subview, attribute: .centerY,  multiplier: 1, constant: 0)
        ]

        addConstraints(newConstraints)
    }

    func pinSubviewToAllEdges(_ subview: UIView) {
        pinSubview(subview, edges: self)
    }

    func pinSubviewToAllEdgesReadable(_ subview: UIView) {
        pinSubview(subview, horizontalEdges: readableContentGuide)
        pinSubview(subview, verticalEdges: self)
    }

    func pinSubviewToAllEdgeMargins(_ subview: UIView) {
        pinSubview(subview, edges: layoutMarginsGuide)
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
