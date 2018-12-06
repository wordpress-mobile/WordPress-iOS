struct KeyboardInfo {
    let animationCurve: UIView.AnimationCurve
    let animationDuration: Double
    let isLocal: Bool
    let frameBegin: CGRect
    let frameEnd: CGRect
}

extension KeyboardInfo {
    init?(_ notification: Foundation.Notification) {
        guard notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillHideNotification else {
            return nil
        }

        guard let u = notification.userInfo,
            let curve = u[UIWindow.keyboardAnimationCurveUserInfoKey] as? Int,
            let aCurve = UIView.AnimationCurve(rawValue: curve),
            let duration = u[UIWindow.keyboardAnimationDurationUserInfoKey] as? Double,
            let local = u[UIWindow.keyboardIsLocalUserInfoKey] as? Bool,
            let begin = u[UIWindow.keyboardFrameBeginUserInfoKey] as? CGRect,
            let end = u[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect else {
                return nil
        }

        animationCurve = aCurve
        animationDuration = duration
        isLocal = local
        frameBegin = begin
        frameEnd = end
    }
}
