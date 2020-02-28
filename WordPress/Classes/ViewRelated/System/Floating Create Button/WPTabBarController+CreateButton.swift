import Gridicons

extension FloatingActionButton {
    class func makeCreateButton() -> FloatingActionButton {
        let button = FloatingActionButton(image: Gridicon.iconOfType(.create))
        button.accessibilityLabel = NSLocalizedString("Create", comment: "Accessibility label for create floating action button")
        button.accessibilityIdentifier = "floatingCreateButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

extension WPTabBarController {

    private enum Constants {
        static let padding: CGFloat = -16
        static let heightWidth: CGFloat = 56
    }

    @objc private func showCreateSheet() {
        showPostTab()
    }

    @objc func addCreateButton() -> FloatingActionButton? {
        guard let trailingAnchor = blogListSplitViewController.viewControllers.first?.view.trailingAnchor else {
            return nil
        }
        let button = addFloatingButton(trailingAnchor: trailingAnchor, bottomAnchor: tabBar.topAnchor)
        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)

        return button
    }

    /// Adds a "Floating Action Button" to the UIViewController's `view`
    /// - Parameters:
    ///   - trailingAnchor: The trailing anchor to anchor the button to, separated by `Constants.padding`
    ///   - bottomAnchor: The bottom anchor to anchor the button to, separated by `Constants.padding`
    private func addFloatingButton(trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) -> FloatingActionButton {
        let button = FloatingActionButton.makeCreateButton()

        view.addSubview(button)

        let trailingConstraint = button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding)
        button.trailingConstraint = trailingConstraint

        NSLayoutConstraint.activate([
            trailingConstraint,
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth)
        ])

        return button
    }
}
