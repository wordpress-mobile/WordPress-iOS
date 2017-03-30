import Foundation
import WordPressShared


struct NavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let icon: UIImage?
    let action: ImmuTableAction?
    let accessoryType: UITableViewCellAccessoryType

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, accessoryType: UITableViewCellAccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct BadgeNavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellBadge.self)

    let title: String
    let icon: UIImage?
    let action: ImmuTableAction?
    let badgeCount: Int
    let accessoryType: UITableViewCellAccessoryType

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, accessoryType: UITableViewCellAccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.badgeCount = badgeCount
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! WPTableViewCellBadge

        cell.textLabel?.text = title
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon
        cell.badgeCount = badgeCount

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

struct LinkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title

        WPStyleGuide.configureTableViewActionCell(cell)
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

struct SwitchRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(SwitchTableViewCell.self)

    let title: String
    let value: Bool
    let action: ImmuTableAction? = nil
    let onChange: (Bool) -> Void

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! SwitchTableViewCell

        cell.textLabel?.text = title
        cell.selectionStyle = .none
        cell.on = value
        cell.onChange = onChange
    }
}
