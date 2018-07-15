import Foundation
import WordPressShared
import Gridicons


struct NavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let detail: String?
    let icon: UIImage?
    let action: ImmuTableAction?
    let accessoryType: UITableViewCellAccessoryType

    init(title: String, detail: String? = nil, icon: UIImage? = nil, badgeCount: Int = 0, accessoryType: UITableViewCellAccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct IndicatorNavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellIndicator.self)

    let title: String
    let icon: UIImage?
    let showIndicator: Bool
    let accessoryType: UITableViewCellAccessoryType
    let action: ImmuTableAction?


    init(title: String, icon: UIImage? = nil, showIndicator: Bool = false, accessoryType: UITableViewCellAccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.showIndicator = showIndicator
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! WPTableViewCellIndicator

        cell.textLabel?.text = title
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon
        cell.showIndicator = showIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct EditableTextRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let value: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = .disclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct EditableAttributedTextRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let value: NSAttributedString
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.attributedText = value
        cell.accessoryType = .disclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }
}


struct TextRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let value: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.selectionStyle = .none

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct CheckmarkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let checked: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        cell.accessoryType = (checked) ? .checkmark : .none

        WPStyleGuide.configureTableViewCell(cell)
    }

}

struct LinkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let action: ImmuTableAction?

    private static let imageSize = CGSize(width: 20, height: 20)
    private var accessoryImageView: UIImageView {
        let image = Gridicon.iconOfType(.external, withSize: LinkRow.imageSize)

        let imageView = UIImageView(image: image)
        imageView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()

        return imageView
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessoryView = accessoryImageView

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct LinkWithValueRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let value: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}

struct ButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        WPStyleGuide.configureTableViewActionCell(cell)
        cell.textLabel?.textAlignment = .center
    }
}

struct DestructiveButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let action: ImmuTableAction?
    let accessibilityIdentifier: String

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessibilityIdentifier = accessibilityIdentifier
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        WPStyleGuide.configureTableViewDestructiveActionCell(cell)
    }
}

struct TextWithButtonRow: ImmuTableRow {
    typealias CellType = TextWithAccessoryButtonCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "TextWithAccessoryButtonCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let title: String
    let subtitle: String?
    let actionLabel: String
    let action: ImmuTableAction? = nil
    let onButtonTap: ImmuTableAction

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.selectionStyle = .none
        cell.mainLabelText = title
        cell.secondaryLabelText = subtitle
        cell.buttonText = actionLabel
        cell.onButtonTap = { self.onButtonTap(self) }
    }
}

struct TextWithButtonIndicatingActivityRow: ImmuTableRow {
    typealias CellType = TextWithAccessoryButtonCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "TextWithAccessoryButtonCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let title: String
    let subtitle: String?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.mainLabelText = title
        cell.secondaryLabelText = subtitle
        cell.button?.showActivityIndicator(true)
    }
}

struct SwitchRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(SwitchTableViewCell.self)

    let title: String
    let value: Bool
    let icon: UIImage?
    let action: ImmuTableAction? = nil
    let onChange: (Bool) -> Void

    init(title: String, value: Bool, icon: UIImage? = nil, onChange: @escaping (Bool) -> Void) {
        self.title = title
        self.value = value
        self.icon = icon
        self.onChange = onChange
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! SwitchTableViewCell

        cell.textLabel?.text = title
        cell.imageView?.image = icon
        cell.selectionStyle = .none
        cell.on = value
        cell.onChange = onChange
    }
}

class ExpandableRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "ExpandableCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    init(title: String,
         expandedText: NSAttributedString?,
         expanded: Bool,
         action: ImmuTableAction?,
         onLinkTap: ((URL) -> Void)?) {
        self.title = title
        self.expandedText = expandedText
        self.expanded = expanded
        self.action = action
        self.onLinkTap = onLinkTap
    }

    typealias CellType = ExpandableCell

    let title: String
    let expandedText: NSAttributedString?
    let action: ImmuTableAction?
    let onLinkTap: ((URL) -> Void)?
    var expanded: Bool

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.titleTextLabel?.text = title
        cell.expandableTextView.attributedText = expandedText
        cell.expanded = expanded
        cell.urlCallback = onLinkTap
    }
}

struct EditableNameValueRow: ImmuTableRow {
    static let cell = ImmuTableCell.nib(
        UINib(nibName: "InlineEditableNameValueCell",
              bundle: nil),
        InlineEditableNameValueCell.self
    )

    let name: String
    let value: String?
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! InlineEditableNameValueCell
        cell.nameLabel.text = name
        cell.valueTextField.text = value
    }
}
