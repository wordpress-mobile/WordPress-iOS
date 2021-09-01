import UIKit

protocol DestructiveAlertHelperLogic {
    var valueToConfirm: String? { get }
    var alert: UIAlertController? { get }
    func makeAlertWithConfirmation(title: String, message: String, valueToConfirm: String, destructiveActionTitle: String, destructiveAction: @escaping () -> Void) -> UIAlertController
}

class DestructiveAlertHelper: DestructiveAlertHelperLogic {
    private(set) var valueToConfirm: String?
    private(set) var alert: UIAlertController?

    func makeAlertWithConfirmation(title: String, message: String, valueToConfirm: String, destructiveActionTitle: String, destructiveAction: @escaping () -> Void) -> UIAlertController {
        self.valueToConfirm = valueToConfirm

        let attributedMessage: NSMutableAttributedString = NSMutableAttributedString(string: message)

        let attributedValue: NSMutableAttributedString = NSMutableAttributedString(string: valueToConfirm)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        attributedValue.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedValue.string.count - 1))
        attributedMessage.append(attributedValue)

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.setValue(attributedMessage, forKey: "attributedMessage")

        let action = UIAlertAction(title: destructiveActionTitle, style: .destructive) { _ in
            destructiveAction()
        }
        action.isEnabled = false
        alert.addAction(action)
        alert.addTextField { [weak self] in
            $0.addTarget(self, action: #selector(self?.textFieldDidChange), for: .editingChanged)
        }

        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alert.addCancelActionWithTitle(cancelTitle)
        self.alert = alert

        return alert
    }
}

// MARK: - Private Methods
private extension DestructiveAlertHelper {
    @objc func textFieldDidChange(_ sender: UITextField) {
        guard let destructiveAction = alert?.actions.first,
              destructiveAction.style == .destructive else {
            return
        }

        let value = valueToConfirm?.lowercased().trim()
        let typedValue = sender.text?.lowercased().trim()
        destructiveAction.isEnabled = value == typedValue
    }
}
