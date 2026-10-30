import UIKit
import WordPressShared
import WordPressUI

@objc protocol InlineEditableNameValueCellDelegate: AnyObject {
    @objc optional func inlineEditableNameValueCell(
        _ cell: InlineEditableNameValueCell,
        valueTextFieldDidChange value: String
    )
    @objc optional func inlineEditableNameValueCell(
        _ cell: InlineEditableNameValueCell,
        valueTextFieldEditingDidEnd text: String
    )
    @objc optional func inlineEditableNameValueCell(
        _ cell: InlineEditableNameValueCell,
        valueTextFieldShouldReturn textField: UITextField
    ) -> Bool
}

class InlineEditableNameValueCell: WPTableViewCell, Reusable {
    typealias ValueSanitizerBlock = (_ value: String?) -> String?

    fileprivate enum Const {
        enum Color {
            static let nameText = UIColor.label
            static let valueText = UIColor.secondaryLabel
        }

        enum Text {
            static let nonBreakingSpace = "\u{00a0}"
            static let space = " "
        }
    }

    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = false
        label.backgroundColor = nil
        label.contentMode = .left
        label.textAlignment = .natural
        // Tapping the label focuses the text field.
        label.isUserInteractionEnabled = true
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }()
    let valueTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = .none
        textField.minimumFontSize = 17
        return textField
    }()
    weak var delegate: InlineEditableNameValueCellDelegate?
    var valueSanitizer: ValueSanitizerBlock?

    override var accessoryType: UITableViewCell.AccessoryType {
        didSet {
            let textFieldEnabled = accessoryType == .none
            valueTextField.isEnabled = textFieldEnabled
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        preservesSuperviewLayoutMargins = true
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.preservesSuperviewLayoutMargins = true
        contentView.insetsLayoutMarginsFromSafeArea = false

        contentView.addSubview(nameLabel)
        contentView.addSubview(valueTextField)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            valueTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            valueTextField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: valueTextField.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: valueTextField.bottomAnchor)
        ])

        selectionStyle = .none

        nameLabel.textColor = Const.Color.nameText
        nameLabel.font = WPStyleGuide.tableviewTextFont()
        nameLabel.numberOfLines = 0
        nameLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(setValueTextFieldAsFirstResponder(_:)))
        )

        valueTextField.textColor = Const.Color.valueText
        valueTextField.tintColor = .placeholderText
        valueTextField.font = WPStyleGuide.tableviewTextFont()
        valueTextField.borderStyle = .none
        valueTextField.delegate = self
        valueTextField.addTarget(
            self,
            action: #selector(textFieldDidChange(textField:)),
            for: UIControl.Event.editingChanged
        )
        valueTextField.addTarget(
            self,
            action: #selector(textEditingDidEnd(textField:)),
            for: UIControl.Event.editingDidEnd
        )
        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            valueTextField.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            valueTextField.textAlignment = .left
        }

        accessoryType = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func textFieldDidChange(textField: UITextField) {
        textField.text = textField.text?.replacingOccurrences(of: Const.Text.space, with: Const.Text.nonBreakingSpace)

        let text = replaceNonBreakingSpaceWithSpace(for: textField)
        delegate?.inlineEditableNameValueCell?(self, valueTextFieldDidChange: text)
    }

    @objc func textEditingDidEnd(textField: UITextField) {
        if let valueSanitizer {
            textField.text = valueSanitizer(textField.text)
        }

        let text = replaceNonBreakingSpaceWithSpace(for: textField)

        textField.text = text

        delegate?.inlineEditableNameValueCell?(self, valueTextFieldEditingDidEnd: text)
    }

    private func replaceNonBreakingSpaceWithSpace(for textField: UITextField) -> String {
        textField.text?.replacingOccurrences(of: Const.Text.nonBreakingSpace, with: Const.Text.space) ?? ""
    }

    @objc func setValueTextFieldAsFirstResponder(_ gesture: UITapGestureRecognizer) {
        valueTextField.becomeFirstResponder()
    }
}

extension InlineEditableNameValueCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.inlineEditableNameValueCell?(self, valueTextFieldShouldReturn: textField) ?? true
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
