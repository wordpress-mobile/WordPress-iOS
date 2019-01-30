final class BottomToolbarOffsetCoordinator {
    private weak var toolbar: UIView?
    private weak var container: UIView?
    private weak var bottomConstraint: NSLayoutConstraint?

    private struct Constants {
        static let bottomMargin: CGFloat = 0.0
    }

    init(toolbar: UIView, container: UIView, bottomConstraint: NSLayoutConstraint) {
        self.toolbar = toolbar
        self.container = container
        self.bottomConstraint = bottomConstraint
    }

    func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc
    private func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else { return }
        guard let container = container else { return }

        let keyboardScreenFrame = payload.frameEnd

        let convertedKeyboardFrame = container.convert(keyboardScreenFrame, from: nil)

        var constraintConstant = convertedKeyboardFrame.height

        if #available(iOS 11.0, *) {
            let bottomInset = container.safeAreaInsets.bottom
            constraintConstant -= bottomInset
        }

        let animationDuration = payload.animationDuration

        bottomConstraint?.constant = constraintConstant
        container.setNeedsUpdateConstraints()

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.container?.layoutIfNeeded()
            },
                       completion: nil)
    }

    @objc
    private func keyboardWillHide(_ notification: Foundation.Notification) {
        bottomConstraint?.constant = Constants.bottomMargin
    }

    private func showBottomToolbar() {
        toolbar?.isHidden = false
    }

    private func hideBottonToolbar() {
        toolbar?.isHidden = true
    }
}
