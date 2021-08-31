import Foundation


protocol EditCommentSingleLineCellDelegate: AnyObject {
    func textUpdatedForCell(_ cell: EditCommentSingleLineCell)
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

        contentView.layer.borderColor = UIColor.red.cgColor
        contentView.layer.borderWidth = 1.0
        contentView.layer.cornerRadius = 10
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
