import UIKit

extension UIView {
    @discardableResult
    func addTopBorder(withColor bgColor: UIColor) -> UIView {
        let borderView = makeBorderView(withColor: bgColor)

        NSLayoutConstraint.activate([
            makeHairlineConstraint(for: borderView.heightAnchor),
            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            borderView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        return borderView
    }

    @discardableResult
    func addBottomBorder(withColor bgColor: UIColor) -> UIView {
        let borderView = makeBorderView(withColor: bgColor)

        NSLayoutConstraint.activate([
            makeHairlineConstraint(for: borderView.heightAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            borderView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        return borderView
    }

    @discardableResult
    func addBottomBorder(withColor bgColor: UIColor, leadingMargin: CGFloat) -> UIView {
        let borderView = makeBorderView(withColor: bgColor)

        NSLayoutConstraint.activate([
            makeHairlineConstraint(for: borderView.heightAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingMargin),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        return borderView
    }

    @discardableResult
    func addBottomBorder(withColor bgColor: UIColor, leadingMargin: CGFloat, trailingMargin: CGFloat) -> UIView {
        let borderView = makeBorderView(withColor: bgColor)

        NSLayoutConstraint.activate([
            makeHairlineConstraint(for: borderView.heightAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingMargin),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingMargin)
        ])
        return borderView
    }

    private func makeBorderView(withColor: UIColor) -> UIView {
        let borderView = UIView()
        borderView.backgroundColor = withColor
        borderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(borderView)

        return borderView
    }

    /// Creates a constraint that keeps the dimension at one pixel of the receiver's
    /// display and updates it when the receiver moves to a display with a different scale.
    ///
    func makeHairlineConstraint(for dimension: NSLayoutDimension) -> NSLayoutConstraint {
        let constraint = dimension.constraint(equalToConstant: .hairlineBorderWidth(traitCollection: traitCollection))
        registerForTraitChanges([UITraitDisplayScale.self]) { (self: UIView, _) in
            constraint.constant = .hairlineBorderWidth(traitCollection: self.traitCollection)
        }
        return constraint
    }
}

extension CGFloat {
    /// The width of one pixel on the display described by the trait collection.
    ///
    static func hairlineBorderWidth(traitCollection: UITraitCollection) -> CGFloat {
        return 1.0 / traitCollection.displayScale
    }
}
