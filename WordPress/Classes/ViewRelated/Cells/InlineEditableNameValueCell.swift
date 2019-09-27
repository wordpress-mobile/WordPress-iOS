import UIKit
import WordPressAuthenticator

@objc protocol InlineEditableNameValueCellDelegate: class {
    @objc optional func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                                    valueTextFieldDidChange valueTextField: UITextField)
    @objc optional func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                                    valueTextFieldEditingDidEnd valueTextField: UITextField)
}

class InlineEditableNameValueCell: WPTableViewCell, NibReusable {

    enum Const {
        enum Color {
            static let nameText = UIColor.text
            static let valueText = UIColor.textSubtle
        }
    }

    @IBOutlet weak var nameValueWidthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueTextField: LoginTextField!
    weak var delegate: InlineEditableNameValueCellDelegate?

    override var accessoryType: UITableViewCell.AccessoryType {
        didSet {
            let textFieldEnabled = accessoryType == .none
            valueTextField.isEnabled = textFieldEnabled
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none

        nameLabel.textColor = Const.Color.nameText
        nameLabel.font = WPStyleGuide.tableviewTextFont()
        nameLabel.numberOfLines = 0
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setValueTextFieldAsFirstResponder(_:))))

        valueTextField.textColor = Const.Color.valueText
        valueTextField.tintColor = .textPlaceholder
        valueTextField.font = WPStyleGuide.tableviewTextFont()
        valueTextField.borderStyle = .none
        valueTextField.addTarget(self,
                                 action: #selector(textFieldDidChange(textField:)),
                                 for: UIControl.Event.editingChanged)
        valueTextField.addTarget(self,
                                 action: #selector(textEditingDidEnd(textField:)),
                                 for: UIControl.Event.editingDidEnd)
        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            valueTextField.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            valueTextField.textAlignment = .left
        }

        accessoryType = .none
    }

    @objc func textFieldDidChange(textField: UITextField) {
        textField.text = textField.text?.replacingOccurrences(of: " ", with: "\u{00a0}")
        delegate?.inlineEditableNameValueCell?(self, valueTextFieldDidChange: textField)
    }

    @objc func textEditingDidEnd(textField: UITextField) {
        textField.text = textField.text?.replacingOccurrences(of: "\u{00a0}", with: " ")
        delegate?.inlineEditableNameValueCell?(self, valueTextFieldEditingDidEnd: textField)
    }

    @objc func setValueTextFieldAsFirstResponder(_ gesture: UITapGestureRecognizer) {
        valueTextField.becomeFirstResponder()
    }
}

extension InlineEditableNameValueCell {
    struct Model {
        var key: String
        var value: String?
        var placeholder: String?
        var valueColor: UIColor?
        var accessoryType: UITableViewCell.AccessoryType?
    }

    func update(with model: Model) {
        nameLabel.text = model.key
        valueTextField.text = model.value
        valueTextField.placeholder = model.placeholder
        valueTextField.textColor = model.valueColor ?? Const.Color.valueText
        accessoryType = model.accessoryType ?? .none
    }
}
