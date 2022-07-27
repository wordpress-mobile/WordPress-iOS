import UIKit
import WordPressAuthenticator

class RegisterDomainDetailsErrorSectionFooter: UITableViewHeaderFooterView, NibReusable {

    @IBOutlet private weak var stackView: UIStackView!

    func addErrorMessage(_ message: String?) {
        let label = errorLabel(message: message)
        stackView.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }

    func setErrorMessages(_ messages: [String]) {
        clearErrorMessages()
        messages.forEach {
            addErrorMessage($0)
        }
    }

    func clearErrorMessages() {
        let subviews = stackView.arrangedSubviews
        for subview in subviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    private func errorLabel(message: String?) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .error
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.numberOfLines = 0
        label.text = message
        return label
    }
}
