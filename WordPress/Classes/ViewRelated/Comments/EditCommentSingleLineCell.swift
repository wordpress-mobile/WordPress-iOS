import Foundation


protocol EditCommentSingleLineCellDelegate: AnyObject {
    func fieldUpdated(_ type: TextFieldStyle, updatedText: String?, isValid: Bool)
}

// Used to determine TextField configuration options.
enum TextFieldStyle {
    case text
    case url
    case email
}


class EditCommentSingleLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textField: UITextField!
    weak var delegate: EditCommentSingleLineCellDelegate?
    private var textFieldStyle: TextFieldStyle = .text

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

}

// MARK: - UITextFieldDelegate

extension EditCommentSingleLineCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func textFieldChanged(_ sender: UITextField) {
        validateText(sender.text)
    }

}

// MARK: - Private Extension

private extension EditCommentSingleLineCell {

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
        let isValid: Bool = {
            switch textFieldStyle {
            case .email:
                return text?.isValidEmail() ?? false
            default:
                return true
            }
        }()

        delegate?.fieldUpdated(textFieldStyle, updatedText: text, isValid: isValid)
    }

}
