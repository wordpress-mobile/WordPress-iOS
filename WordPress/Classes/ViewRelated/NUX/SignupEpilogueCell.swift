import UIKit
import WordPressAuthenticator

protocol SignupEpilogueCellDelegate: AnyObject {
    func updated(value: String, forType: EpilogueCellType)
    func changed(value: String, forType: EpilogueCellType)
}

enum EpilogueCellType: Int {
    case displayName
    case username
    case password
}

class SignupEpilogueCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellField: LoginTextField!

    // Used to layout cellField when cellLabel is shown or hidden.
    @IBOutlet var cellFieldLeadingConstraintWithLabel: NSLayoutConstraint!
    @IBOutlet var cellFieldLeadingConstraintWithoutLabel: NSLayoutConstraint!

    // Used to layout cellField when disclosure icon is shown or hidden.
    @IBOutlet var cellFieldTrailingConstraint: NSLayoutConstraint!
    private var cellFieldTrailingMarginDefault: CGFloat = 0
    private let cellFieldTrailingMarginDisclosure: CGFloat = 10

    // Used to inset the separator lines.
    @IBOutlet var cellLabelLeadingConstraint: NSLayoutConstraint!

    // Used to apply a top margin to the Password field.
    @IBOutlet var cellFieldTopConstraint: NSLayoutConstraint!
    private let passwordTopMargin: CGFloat = 16

    private var cellType: EpilogueCellType?
    open weak var delegate: SignupEpilogueCellDelegate?

    // MARK: - UITableViewCell

    override func awakeFromNib() {
        super.awakeFromNib()
        cellFieldTrailingMarginDefault = cellFieldTrailingConstraint.constant
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        accessoryType = .none
        cellField.textContentType = nil
        isAccessibilityElement = false
    }

    override var accessibilityLabel: String? {
        get {
            let emptyValue = NSLocalizedString("Empty", comment: "Accessibility value presented in the signup epilogue for an empty value.")
            let secureTextValue = NSLocalizedString("Secure text", comment: "Accessibility value presented in the signup epilogue for a password value.")

            let labelValue = cellLabel.text ?? emptyValue

            let fieldValue: String
            if let cellText = cellField.text, !cellText.isEmpty {
                if cellType == .password {
                    fieldValue = secureTextValue    // let's refrain from reading the password aloud
                } else {
                    fieldValue = cellText
                }
            } else {
                fieldValue = emptyValue
            }

            let value = "\(labelValue), \(fieldValue)"

            return value
        }
        set {
            super.accessibilityLabel = newValue
        }
    }

    // MARK: - Public Methods

    func configureCell(forType newCellType: EpilogueCellType,
                       labelText: String? = nil,
                       fieldValue: String? = nil,
                       fieldPlaceholder: String? = nil) {

        cellType = newCellType

        cellLabel.text = labelText
        cellLabel.textColor = .label

        cellField.text = fieldValue
        cellField.placeholder = fieldPlaceholder
        cellField.delegate = self

        configureForPassword()

        selectionStyle = .none

        configureAccessoryType(for: newCellType)
        configureTextContentTypeIfNeeded(for: newCellType)
        configureAccessibility(for: newCellType)
        configureEditable(for: newCellType)
        configureKeyboardReturnKey(for: newCellType)

        addBottomBorder(withColor: .separator, leadingMargin: cellLabelLeadingConstraint.constant)

        // TODO: remove this when `WordPressAuthenticatorStyle:textFieldBackgroundColor` is updated.
        // This background color should be inherited from LoginTextField.
        // However, since the Auth views haven't been updated, the color is incorrect.
        // So for now we'll override it here.
        cellField.backgroundColor = .systemBackground
    }

}

extension SignupEpilogueCell: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let cellType = cellType,
            let originalText = textField.text,
            cellType == .displayName || cellType == .password {
            let updatedText = NSString(string: originalText).replacingCharacters(in: range, with: string)
            delegate?.changed(value: updatedText, forType: cellType)
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if let cellType = cellType,
            let updatedText = textField.text {
            delegate?.updated(value: updatedText, forType: cellType)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cellField.endEditing(true)
        return true
    }
}

private extension SignupEpilogueCell {

    func configureForPassword() {
        let isPassword = (cellType == .password)
        cellLabel.isHidden = isPassword

        cellField.isSecureTextEntry = isPassword
        cellField.showSecureTextEntryToggle = isPassword
        cellField.textAlignment = isPassword ? .left : .right
        cellField.textColor = isPassword ? .label : .secondaryLabel

        cellFieldLeadingConstraintWithLabel.isActive = !isPassword
        cellFieldLeadingConstraintWithoutLabel.isActive = isPassword
        cellFieldTopConstraint.constant = isPassword ? passwordTopMargin : 0
    }

    func configureAccessibility(for cellType: EpilogueCellType) {
        if cellType == .username {
            accessibilityTraits.insert(.button) // selection transitions to SignupUsernameViewController
            isAccessibilityElement = true       // this assures double-tap properly captures cell selection
        }

        switch cellType {
        case .displayName:
            cellField.accessibilityIdentifier = "Display Name Field"
        case .username:
            cellField.accessibilityIdentifier = "Username Field"
        case .password:
            cellField.accessibilityIdentifier = "Password Field"
            cellLabel.isAccessibilityElement = false
        }
    }

    func configureAccessoryType(for cellType: EpilogueCellType) {
        if cellType == .username {
            accessoryType = .disclosureIndicator
            cellFieldTrailingConstraint.constant = cellFieldTrailingMarginDisclosure
        } else {
            accessoryType = .none
            cellFieldTrailingConstraint.constant = cellFieldTrailingMarginDefault
        }
    }

    func configureTextContentTypeIfNeeded(for cellType: EpilogueCellType) {
        guard !UITestConfigurator.isEnabled(.disableAutofill) else {
            return
        }
        switch cellType {
        case .displayName:
            cellField.textContentType = .name
        case .username:
            cellField.textContentType = .username
        case .password:
            cellField.textContentType = .newPassword
        }
    }

    func configureEditable(for cellType: EpilogueCellType) {
        if cellType == .username {
            cellField.isEnabled = false
        } else {
            cellField.isEnabled = true
        }
    }

    func configureKeyboardReturnKey(for cellType: EpilogueCellType) {
        if cellType == .displayName {
            cellField.enablesReturnKeyAutomatically = true
        }
    }

}
