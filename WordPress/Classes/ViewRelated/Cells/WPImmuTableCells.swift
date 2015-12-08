import Foundation
import UIKit
import WordPressShared.WPTableViewCell

class WPReusableTableViewCell: WPTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
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

struct NavigationItemRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellDefault)

    let title: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.accessoryType = .DisclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct EditableTextRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let value: String
    let action: ImmuTableActionType?

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
    let action: ImmuTableActionType? = nil

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
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}

struct LinkWithValueRow : ImmuTableRow {
    static let cell = ImmuTableCell.Class(WPTableViewCellValue1)

    let title: String
    let value: String
    let action: ImmuTableActionType?

    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value

        WPStyleGuide.configureTableViewActionCell(cell)
    }
}

struct SwitchRow: ImmuTableRow {
    static let cell = ImmuTableCell.Class(SwitchTableViewCell)

    let title: String
    let value: Bool
    let action: ImmuTableActionType? = nil
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

    let action: ImmuTableActionType? = nil

    func configureCell(cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.title = title
        cell.value = value
        cell.onChange = onChange

        cell.minValue = MediaMinImageSizeDimension
        cell.maxValue = MediaMaxImageSizeDimension
    }
}
