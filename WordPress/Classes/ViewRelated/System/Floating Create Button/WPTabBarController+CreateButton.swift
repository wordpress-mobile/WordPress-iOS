import Gridicons

extension FloatingActionButton {
    class func createButton() -> UIButton {
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

    @objc func showCreateSheet() {
        showPostTab()
    }

    @objc func setupCreateButton() -> HideShowCoordinator? {
        guard let trailingAnchor = blogListSplitViewController.viewControllers.first?.view.trailingAnchor else {
            return nil
        }
        let button = addFloatingButton(trailingAnchor: trailingAnchor, bottomAnchor: tabBar.topAnchor)
        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)

        let coordinator = setupHideShowCoordinator(view: button)

        return coordinator
    }

    /// Sets up the HideShowCoordinator object
    /// - Parameter view: The view to hide & show
    private func setupHideShowCoordinator(view: UIView) -> HideShowCoordinator {
        let coordinator = HideShowCoordinator()

        let showForNavigation: (UIViewController) -> Bool = { viewController in
            let classes = [BlogDetailsViewController.self, PostListViewController.self, PageListViewController.self]
            let vcType = type(of: viewController)
            return classes.contains { classType in
                return vcType == classType
            }
        }

        coordinator.observe(blogListNavigationController, showFor: showForNavigation, view: view)

        let showForTab: (UIViewController) -> Bool = { [weak self] viewController in
            return viewController == self?.blogListSplitViewController
        }

        coordinator.observe(self, showFor: showForTab, view: view)

        return coordinator
    }

    /// Adds a "Floating Action Button" to the UIViewController's `view`
    /// - Parameters:
    ///   - trailingAnchor: The trailing anchor to anchor the button to, separated by `Constants.padding`
    ///   - bottomAnchor: The bottom anchor to anchor the button to, separated by `Constants.padding`
    private func addFloatingButton(trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) -> UIButton {
        let button = FloatingActionButton.createButton()

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth)
        ])

        return button
    }
}
