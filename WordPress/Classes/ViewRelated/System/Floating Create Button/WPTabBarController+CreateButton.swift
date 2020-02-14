extension WPTabBarController {

    private enum Constants {
        static let padding: CGFloat = -16
        static let heightWidth: CGFloat = 56
    }

    @objc func addFloatingButton() {

        let button = FloatingActionButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showPostViewController(_:)), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: Constants.padding),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth)
        ])
    }

    @objc func showPostViewController(_ sender: UIView) {
        showPostTab()
    }
}
