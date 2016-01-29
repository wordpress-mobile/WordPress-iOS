import Foundation
import UIKit
import WordPressShared.WPTableViewCell

class WPReusableTableViewCell: WPTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
        textLabel?.textAlignment = .Left
        detailTextLabel?.text = nil
        imageView?.image = nil
        accessoryType = .None
        selectionStyle = .Default
    }
}

class WPTableViewCellDefault: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellSubtitle: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellValue1: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellValue2: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value2, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellBadge: WPTableViewCellDefault {
    var badgeCount: Int = 0 {
        didSet {
            if badgeCount > 0 {
                badgeLabel.text = String(badgeCount)
                accessoryView = badgeLabel
                accessoryType = .None
            } else {
                accessoryView = nil
                accessoryType = .DisclosureIndicator
            }
        }
    }

    private lazy var badgeLabel: UILabel = {
        let label = UILabel(frame: CGRect(origin: CGPointZero, size: WPTableViewCellBadge.badgeSize))
        label.layer.masksToBounds = true
        label.layer.cornerRadius = WPTableViewCellBadge.badgeCornerRadius
        label.textAlignment = .Center
        label.backgroundColor = WPStyleGuide.newKidOnTheBlockBlue()
        label.textColor = UIColor.whiteColor()
        return label
    }()

    private static let badgeSize = CGSize(width: 50, height: 30)
    private static var badgeCornerRadius: CGFloat {
        return badgeSize.height / 2
    }
}

struct NavigationItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)

    let title: String
    let icon: UIImage?
    let action: ImmuTableAction?

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, action: ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessoryType = .DisclosureIndicator
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

    init(title: String, icon: UIImage? = nil, badgeCount: Int = 0, action: ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.badgeCount = badgeCount
        self.action = action
    }

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! WPTableViewCellBadge

        cell.textLabel?.text = title
        cell.accessoryType = .None
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

        cell.minValue = MediaMinImageSizeDimension
        cell.maxValue = MediaMaxImageSizeDimension
    }
}
