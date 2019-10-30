extension UIView {
    @discardableResult
    func addTopBorder(withColor bgColor: UIColor) -> UIView {
        let borderView = makeBorderView(withColor: bgColor)

        NSLayoutConstraint.activate([
            borderView.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
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
            borderView.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            borderView.widthAnchor.constraint(equalTo: widthAnchor)
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
}

extension CGFloat {
    static var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }
}
