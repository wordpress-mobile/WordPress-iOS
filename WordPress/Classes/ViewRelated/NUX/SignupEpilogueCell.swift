import UIKit

class SignupEpilogueCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellField: LoginTextField!

    // MARK: - Public Methods

    func configureCell(labelText: String,
                       fieldValue: String? = nil,
                       fieldPlaceholder: String? = nil,
                       showSecureTextEntry: Bool = false) {
        cellLabel.text = labelText
        cellField.text = fieldValue
        cellField.showSecureTextEntryToggle = showSecureTextEntry
        cellField.placeholder = fieldPlaceholder
        selectionStyle = .none
    }

}
