import UIKit
import WordPressAuthenticator

class InlineEditableNameValueCell: WPTableViewCell {

    @IBOutlet weak var nameValueWidthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueTextField: LoginTextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        nameLabel.textColor = WPStyleGuide.darkGrey()
        nameLabel.font = WPStyleGuide.tableviewTextFont()
        nameLabel.numberOfLines = 0
        valueTextField.textColor = WPStyleGuide.greyDarken10()
        valueTextField.font = WPStyleGuide.tableviewTextFont()
        valueTextField.borderStyle = .none
        valueTextField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        // swiftlint:disable:next inverse_text_alignment
        valueTextField.textAlignment = .right
    }
}
