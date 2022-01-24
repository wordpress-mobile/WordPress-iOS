import Foundation

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


class InlineEditableSingleLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textField: UITextField!
    weak var delegate: InlineEditableSingleLineCellDelegate?
    private(set) var textFieldStyle: TextFieldStyle = .text
    private(set) var isValid: Bool = true

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    func configure(text: String? = nil, style: TextFieldStyle = .text) {
        textField.text = text
        textFieldStyle = style
        applyTextFieldStyle()
    }

    func showInvalidState(_ show: Bool = true) {
        guard show else {
            contentView.layer.borderColor = UIColor.clear.cgColor
            return
        }

        contentView.layer.borderColor = UIColor.error.cgColor
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

    @IBAction func textFieldChanged(_ sender: UITextField) {
        validateText(sender.text)
    }

}

// MARK: - Private Extension

private extension InlineEditableSingleLineCell {

    func configureCell() {
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = .text
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

}
