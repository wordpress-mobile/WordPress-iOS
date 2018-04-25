import UIKit
import WordPressAuthenticator


protocol SignupEpilogueCellDelegate {
    func updated(value: String, forType: EpilogueCellType)
    func changed(value: String, forType: EpilogueCellType)
    func usernameSelected()
}

enum EpilogueCellType {
    case displayName
    case username
    case password
}

class SignupEpilogueCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellField: LoginTextField!

    private var cellType: EpilogueCellType?
    open var delegate: SignupEpilogueCellDelegate?

    // MARK: - Public Methods

    func configureCell(forType newCellType: EpilogueCellType,
                       labelText: String,
                       fieldValue: String? = nil,
                       fieldPlaceholder: String? = nil) {
        cellType = newCellType
        cellLabel.text = labelText
        cellField.text = fieldValue
        cellField.placeholder = fieldPlaceholder
        cellField.delegate = self
        cellField.isSecureTextEntry = (cellType == .password)
        selectionStyle = .none

        if cellType == .username {
            accessoryType = .disclosureIndicator
        } else {
            accessoryType = .none
        }
    }

}


extension SignupEpilogueCell: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let cellType = cellType, cellType == .displayName || cellType == .password {
            let updatedText = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            delegate?.changed(value: updatedText, forType: cellType)
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if let cellType = cellType,
            let updatedText = textField.text {
            delegate?.updated(value: updatedText, forType: cellType)
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let cellType = cellType,
            cellType == .username {
            delegate?.usernameSelected()
            return false
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cellField.endEditing(true)
        return true
    }

}
