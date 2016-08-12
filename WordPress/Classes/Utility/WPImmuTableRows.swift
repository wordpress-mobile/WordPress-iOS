import Foundation
import WordPressShared


struct NavigationItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)

    let title: String
    let icon: UIImage?
    let action: ImmuTableAction?
    let accessoryType: UITableViewCellAccessoryType

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, accessoryType: UITableViewCellAccessoryType = .DisclosureIndicator, action: ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct BadgeNavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellBadge)

    let title: String
    let icon: UIImage?
    let action: ImmuTableAction?
    let badgeCount: Int
    let accessoryType: UITableViewCellAccessoryType

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, accessoryType: UITableViewCellAccessoryType = .DisclosureIndicator, action: ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.badgeCount = badgeCount
        self.accessoryType = accessoryType
        self.action = action
    }

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! WPTableViewCellBadge

        cell.textLabel?.text = title
        cell.accessoryType = accessoryType
        cell.imageView?.image = icon
        cell.badgeCount = badgeCount

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct EditableTextRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let value: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = .DisclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct TextRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let value: String
    let action: ImmuTableAction? = nil

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.selectionStyle = .None

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct LinkRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}

struct LinkWithValueRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let value: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}

struct ButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)

    let title: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title

        WPStyleGuide.configureTableViewActionCell(cell)
        cell.textLabel?.textAlignment = .Center
    }
}

struct DestructiveButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)

    let title: String
    let action: ImmuTableAction?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title

        WPStyleGuide.configureTableViewDestructiveActionCell(cell)
    }
}

struct SwitchRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(SwitchTableViewCell)

    let title: String
    let value: Bool
    let action: ImmuTableAction? = nil
    let onChange: Bool -> Void

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! SwitchTableViewCell

        cell.textLabel?.text = title
        cell.selectionStyle = .None
        cell.on = value
        cell.onChange = onChange
    }
}

struct MediaSizeRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: NSBundle(forClass: CellType.self))
        return ImmuTableCell.Nib(nib, CellType.self)
    }()
    static let customHeight: Float? = CellType.height

    let title: String
    let value: Int
    let onChange: Int -> Void

    let action: ImmuTableAction? = nil

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.title = title
        cell.value = value
        cell.onChange = onChange
        cell.selectionStyle = .None

        (cell.minValue, cell.maxValue) = MediaSettings().allowedImageSizeRange
    }
}
