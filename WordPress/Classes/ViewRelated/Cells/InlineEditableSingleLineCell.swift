import UIKit
import WordPressUI

// UITableViewCell that displays an editable UITextField to allow text to be modified inline.
// The text field and keyboard styles are set based on the TextFieldStyle. The default is `text`.
// The delegate is notified as the text is modified.

protocol InlineEditableSingleLineCellDelegate: AnyObject {
    func textUpdatedForCell(_ cell: InlineEditableSingleLineCell)
}

// Used to determine TextField configuration options.
enum TextFieldStyle {
    case text
    case url
    case email
}

class InlineEditableSingleLineCell: UITableViewCell, Reusable {

    // MARK: - Properties

    let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.adjustsFontForContentSizeCategory = true
        textField.autocapitalizationType = .none
        textField.minimumFontSize = 17
        textField.clearButtonMode = .whileEditing
        textField.enablesReturnKeyAutomatically = true
        return textField
    }()
    weak var delegate: InlineEditableSingleLineCellDelegate?
    private(set) var textFieldStyle: TextFieldStyle = .text
    private(set) var isValid: Bool = true

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        preservesSuperviewLayoutMargins = true
        selectionStyle = .none
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.preservesSuperviewLayoutMargins = true
        contentView.insetsLayoutMarginsFromSafeArea = false

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor, constant: 11)
        ])

        configureCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String? = nil, style: TextFieldStyle = .text, disabled: Bool = false) {
        textField.text = text
        textFieldStyle = style
        applyTextFieldStyle()
        configureInteraction(disabled)
    }

    func showInvalidState(_ show: Bool = true) {
        guard show else {
            contentView.layer.borderColor = UIColor.clear.cgColor
            return
        }

        contentView.layer.borderColor = UIAppColor.error.cgColor
        contentView.layer.borderWidth = 1.0
        contentView.layer.cornerRadius = 10
    }
}

// MARK: - UITextFieldDelegate

extension InlineEditableSingleLineCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        validateText(sender.text)
    }
}

// MARK: - Private Extension

private extension InlineEditableSingleLineCell {

    func configureCell() {
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = .label
    }

    func applyTextFieldStyle() {
        switch textFieldStyle {
        case .text:
            textField.autocorrectionType = .yes
            textField.keyboardType = .default
            textField.returnKeyType = .default
        case .url:
            textField.autocorrectionType = .no
            textField.keyboardType = .URL
        case .email:
            textField.autocorrectionType = .no
            textField.keyboardType = .emailAddress
        }
    }

    func validateText(_ text: String?) {
        isValid = {
            switch textFieldStyle {
            case .email:
                return text?.isValidEmail() ?? false
            default:
                return true
            }
        }()

        delegate?.textUpdatedForCell(self)
    }

    func configureInteraction(_ disabled: Bool) {
        isUserInteractionEnabled = !disabled
        textField.textColor = disabled ? .secondaryLabel : .label
    }
}
