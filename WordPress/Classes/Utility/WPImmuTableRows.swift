import Foundation
import WordPressShared
import Gridicons

struct NavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let detail: String?
    let icon: UIImage?
    let tintColor: UIColor?
    let action: ImmuTableAction?
    let accessoryType: UITableViewCell.AccessoryType
    let accessibilityIdentifier: String?
    let loading: Bool

    init(title: String, detail: String? = nil, icon: UIImage? = nil, tintColor: UIColor? = nil, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction, accessibilityIdentifier: String? = nil, loading: Bool = false) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tintColor = tintColor
        self.accessoryType = accessoryType
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
        self.loading = loading
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.imageView?.image = icon
        cell.accessibilityIdentifier = accessibilityIdentifier

        if loading {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            cell.accessoryView = indicator
        } else {
            cell.accessoryType = accessoryType
        }

        WPStyleGuide.configureTableViewCell(cell)

        cell.imageView?.tintColor = tintColor ?? .secondaryLabel
    }
}

struct IndicatorNavigationItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellIndicator.self)

    let title: String
    let icon: UIImage?
    let tintColor: UIColor?
    let showIndicator: Bool
    let accessoryType: UITableViewCell.AccessoryType
    let action: ImmuTableAction?

    init(title: String, icon: UIImage? = nil, tintColor: UIColor?, showIndicator: Bool = false, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, action: @escaping ImmuTableAction) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
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

        cell.imageView?.tintColor = tintColor ?? .secondaryLabel
    }
}

struct EditableTextRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

    let title: String
    let value: String
    let accessoryImage: UIImage?
    let action: ImmuTableAction?
    let fieldName: String?

    init(title: String, value: String, accessoryImage: UIImage? = nil, action: ImmuTableAction?, fieldName: String? = nil) {
        self.title = title
        self.value = value
        self.accessoryImage = accessoryImage
        self.action = action
        self.fieldName = fieldName
    }

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessibilityLabel = title
        cell.accessibilityValue = value
        if cell.isUserInteractionEnabled {
            cell.accessibilityHint = NSLocalizedString("Tap to edit", comment: "Accessibility hint prompting the user to tap a table row to edit its value.")
        }
        cell.accessoryType = .disclosureIndicator
        if accessoryImage != nil {
            cell.accessoryView = UIImageView(image: accessoryImage)
        }

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
        cell.accessibilityLabel = title
        cell.accessibilityValue = value

        cell.selectionStyle = .none

        WPStyleGuide.configureTableViewCell(cell)
    }
}

struct CheckmarkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)

    let title: String
    let subtitle: String?
    let checked: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = title
        cell.accessibilityHint = subtitle

        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        cell.selectionStyle = .none
        cell.accessoryType = (checked) ? .checkmark : .none

        WPStyleGuide.configureTableViewCell(cell)
    }

    init(title: String, subtitle: String? = nil, checked: Bool, action: ImmuTableAction?) {
        self.title = title
        self.subtitle = subtitle
        self.checked = checked
        self.action = action
    }

}

struct ActivityIndicatorRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let animating: Bool
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title

        let indicator: UIActivityIndicatorView
        indicator = UIActivityIndicatorView(style: .medium)

        if animating {
            indicator.startAnimating()
        }

        cell.accessoryView = indicator

        WPStyleGuide.configureTableViewCell(cell)
    }

}

struct LinkRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let action: ImmuTableAction?

    private static let imageSize = CGSize(width: 20, height: 20)
    private var accessoryImageView: UIImageView {
        let image = UIImage.gridicon(.external, size: LinkRow.imageSize)

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

/// Create a row that navigates to a new ViewController.
/// Uses the WordPress branded blue and is left aligned.
///
struct BrandedNavigationRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellIndicator.self)

    let title: String
    let showIndicator: Bool
    let action: ImmuTableAction?
    let accessibilityIdentifier: String?

    init(title: String, action: @escaping ImmuTableAction, showIndicator: Bool = false, accessibilityIdentifier: String? = nil) {
        self.title = title
        self.showIndicator = showIndicator
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? WPTableViewCellIndicator else {
            return
        }
        cell.textLabel?.text = title
        WPStyleGuide.configureTableViewCell(cell)
        cell.textLabel?.textColor = AppStyleGuide.primary
        cell.showIndicator = showIndicator
        cell.accessibilityTraits = .button
        cell.accessibilityIdentifier = accessibilityIdentifier
    }
}

struct ButtonRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    var textAlignment: NSTextAlignment = .center
    var isLoading = false
    let action: ImmuTableAction?
    var accessibilityIdentifier: String?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        WPStyleGuide.configureTableViewActionCell(cell)
        cell.textLabel?.textAlignment = textAlignment

        if isLoading {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            cell.accessoryView = indicator
        } else {
            cell.accessoryView = nil
        }

        cell.accessibilityIdentifier = accessibilityIdentifier
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
    let isUserInteractionEnabled: Bool
    let action: ImmuTableAction? = nil
    let onChange: (Bool) -> Void
    let accessibilityIdentifier: String?

    init(title: String,
         value: Bool,
         icon: UIImage? = nil,
         isUserInteractionEnabled: Bool = true,
         onChange: @escaping (Bool) -> Void,
         accessibilityIdentifier: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.isUserInteractionEnabled = isUserInteractionEnabled
        self.onChange = onChange
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! SwitchTableViewCell

        cell.textLabel?.text = title
        cell.imageView?.image = icon
        cell.isUserInteractionEnabled = isUserInteractionEnabled
        cell.selectionStyle = .none
        cell.on = value
        cell.onChange = onChange
        cell.flipSwitch.accessibilityIdentifier = accessibilityIdentifier
    }
}

struct SwitchWithSubtitleRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(SwitchWithSubtitleTableViewCell.self)

    let title: String
    let value: Bool
    let subtitle: String?
    let icon: UIImage?
    let action: ImmuTableAction? = nil
    let onChange: (Bool) -> Void
    let accessibilityIdentifier: String?

    init(title: String, value: Bool, subtitle: String? = nil, icon: UIImage? = nil, onChange: @escaping (Bool) -> Void, accessibilityIdentifier: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.onChange = onChange
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! SwitchWithSubtitleTableViewCell

        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        cell.imageView?.image = icon
        cell.selectionStyle = .none
        cell.on = value
        cell.onChange = onChange
        cell.flipSwitch.accessibilityIdentifier = accessibilityIdentifier
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
