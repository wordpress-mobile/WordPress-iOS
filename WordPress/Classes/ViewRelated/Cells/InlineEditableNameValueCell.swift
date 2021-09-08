import UIKit
import WordPressAuthenticator

@objc protocol InlineEditableNameValueCellDelegate: AnyObject {
    @objc optional func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                                    valueTextFieldDidChange value: String)
    @objc optional func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                                    valueTextFieldEditingDidEnd text: String)
    @objc optional func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                                    valueTextFieldShouldReturn textField: UITextField) -> Bool

}

class InlineEditableNameValueCell: WPTableViewCell, NibReusable {
    typealias ValueSanitizerBlock = (_ value: String?) -> String?

    fileprivate enum Const {
        enum Color {
            static let nameText = UIColor.text
            static let valueText = UIColor.textSubtle
        }

        enum Text {
            static let nonBreakingSpace = "\u{00a0}"
            static let space = " "
        }
    }

    @IBOutlet weak var nameValueWidthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueTextField: LoginTextField!
    weak var delegate: InlineEditableNameValueCellDelegate?
    var valueSanitizer: ValueSanitizerBlock?

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
        valueTextField.delegate = self
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
        textField.text = textField.text?.replacingOccurrences(of: Const.Text.space, with: Const.Text.nonBreakingSpace)

        let text = replaceNonBreakingSpaceWithSpace(for: textField)
        delegate?.inlineEditableNameValueCell?(self, valueTextFieldDidChange: text)
    }

    @objc func textEditingDidEnd(textField: UITextField) {
        if let valueSanitizer = valueSanitizer {
            textField.text = valueSanitizer(textField.text)
        }

        let text = replaceNonBreakingSpaceWithSpace(for: textField)

        textField.text = text

        delegate?.inlineEditableNameValueCell?(self, valueTextFieldEditingDidEnd: text)
    }

    private func replaceNonBreakingSpaceWithSpace(for textField: UITextField) -> String {
        return textField.text?.replacingOccurrences(of: Const.Text.nonBreakingSpace, with: Const.Text.space) ?? ""
    }

    @objc func setValueTextFieldAsFirstResponder(_ gesture: UITapGestureRecognizer) {
        valueTextField.becomeFirstResponder()
    }
}

extension InlineEditableNameValueCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.inlineEditableNameValueCell?(self, valueTextFieldShouldReturn: textField) ?? true
    }
}

extension InlineEditableNameValueCell {
    struct Model {
        var key: String
        var value: String?
        var placeholder: String?
        var valueColor: UIColor?
        var accessoryType: UITableViewCell.AccessoryType?
        var valueSanitizer: ValueSanitizerBlock?
    }

    func update(with model: Model) {
        nameLabel.text = model.key
        valueTextField.text = model.value
        valueTextField.placeholder = model.placeholder
        valueTextField.textColor = model.valueColor ?? Const.Color.valueText
        accessoryType = model.accessoryType ?? .none
        valueSanitizer = model.valueSanitizer
    }
}
