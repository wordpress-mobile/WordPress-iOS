import UIKit
import WordPressAuthenticator

protocol InlineEditableNameValueCellDelegate: class {
    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                     valueTextFieldDidChange valueTextField: UITextField)
}

class InlineEditableNameValueCell: WPTableViewCell, NibReusable {

    enum Const {
        enum Color {
            static let nameText = WPStyleGuide.darkGrey()
            static let valueText = WPStyleGuide.greyDarken10()
        }

        enum ValueTextFieldEdgeInset {
            static let accessoryTypeDisclosure = UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 0)
            static let accessoryTypeNone = UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 10)
        }
    }

    @IBOutlet weak var nameValueWidthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueTextField: LoginTextField!
    weak var delegate: InlineEditableNameValueCellDelegate?

    override var accessoryType: UITableViewCellAccessoryType {
        didSet {
            switch accessoryType {
            case .disclosureIndicator:
                valueTextField.contentInsets = Const.ValueTextFieldEdgeInset.accessoryTypeDisclosure
                valueTextField.isEnabled = false
            default:
                valueTextField.contentInsets = Const.ValueTextFieldEdgeInset.accessoryTypeNone
                valueTextField.isEnabled = true
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        nameLabel.textColor = Const.Color.nameText
        nameLabel.font = WPStyleGuide.tableviewTextFont()
        nameLabel.numberOfLines = 0
        valueTextField.textColor = Const.Color.valueText
        valueTextField.font = WPStyleGuide.tableviewTextFont()
        valueTextField.borderStyle = .none
        valueTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)),
                                 for: UIControlEvents.editingChanged)
        accessoryType = .none
        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            valueTextField.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            valueTextField.textAlignment = .left
        }
    }

    @objc func textFieldDidChange(textField: UITextField) {
        delegate?.inlineEditableNameValueCell(self, valueTextFieldDidChange: textField)
    }
}

extension InlineEditableNameValueCell {
    struct Model {
        var key: String
        var value: String?
        var placeholder: String?
        var valueColor: UIColor?
        var accessoryType: UITableViewCellAccessoryType?
    }

    func update(with model: Model) {
        nameLabel.text = model.key
        valueTextField.text = model.value
        valueTextField.placeholder = model.placeholder
        valueTextField.textColor = model.valueColor ?? Const.Color.valueText
        accessoryType = model.accessoryType ?? .none
    }
}
