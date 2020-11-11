import Foundation

/// A tap gesture recognizer that works with a closure, instead of an action and target.
///
class BindableTapGestureRecognizer: UITapGestureRecognizer {
    typealias Action = (_ sender: BindableTapGestureRecognizer) -> Void

    let action: Action

    init(action: @escaping Action) {
        self.action = action

        super.init(target: nil, action: nil)

        addTarget(self, action: #selector(actionHandler))
    }

    @objc
    private func actionHandler() {
        action(self)
    }
}
