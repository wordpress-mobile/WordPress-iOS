import Foundation

class EditCommentSingleLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textField: UITextField!

    // Used to determine TextField configuration options.
    enum TextFieldStyle {
        case text
        case url
        case email
    }

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    func configure(text: String? = nil, style: TextFieldStyle = .text) {
        applyTextFieldStyle(style)
        textField.text = text
    }

}

// MARK: - UITextFieldDelegate

extension EditCommentSingleLineCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

// MARK: - Private Extension

private extension EditCommentSingleLineCell {

    func configureCell() {
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = .text
    }

    func applyTextFieldStyle(_ style: TextFieldStyle) {
        switch style {
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

}
