import UIKit
import WordPressUI

class RegisterDomainDetailsErrorSectionFooter: UITableViewHeaderFooterView, Reusable {

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 1
        return stackView
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(stackView)
        let guide = contentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Metrics.topInset),
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Metrics.horizontalInset),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Metrics.horizontalInset),
            stackView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Metrics.bottomInset)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        label.textColor = UIAppColor.error
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.numberOfLines = 0
        label.text = message
        return label
    }

    private enum Metrics {
        static let topInset: CGFloat = 8
        static let bottomInset: CGFloat = 12
        static let horizontalInset: CGFloat = 18
    }
}
