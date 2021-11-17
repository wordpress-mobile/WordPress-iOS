import Foundation

typealias AboutScreenSection = [AboutItem]

/// Users of UnifiedAboutViewController must provide a configuration conforming to this protocol.
/// It provides a list of AboutItems, grouped into sections, which will be displayed in the about screen's table view.
protocol AboutScreenConfiguration {
    var sections: [AboutScreenSection] { get }
}

typealias AboutItemAction = ((AboutItemActionContext) -> Void)

struct AboutItemActionContext {
    /// The About Screen view controller itself.
    let viewController: UIViewController

    /// If the action was triggered by the user interacting with a specific view, it'll be available here.
    let sourceView: UIView?
}

/// Defines a single row in the unified about screen.
///
struct AboutItem {
    /// Title displayed in the main textLabel of the item's table row
    let title: String

    /// Subtitle displayed in the detailTextLabel of the item's table row
    let subtitle: String?

    /// Which cell style should be used to render the item's cell. See `AboutItemCellStyle` for options.
    let cellStyle: AboutItemCellStyle

    /// The accessory type that should be used for the item's table row
    let accessoryType: UITableViewCell.AccessoryType

    /// If `true`, the item's table row will hide its bottom separator
    let hidesSeparator: Bool

    /// An optional action that can be performed when the item's table row is tapped.
    /// The action will be passed an `AboutItemActionContext` containing references to the view controller
    /// and the source view that triggered the action.
    let action: AboutItemAction?

    init(title: String, subtitle: String? = nil, cellStyle: AboutItemCellStyle = .default, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, hidesSeparator: Bool = false, action: AboutItemAction? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.cellStyle = cellStyle
        self.accessoryType = accessoryType
        self.hidesSeparator = hidesSeparator
        self.action = action
    }

    enum AboutItemCellStyle: String {
        // Displays only a title
        case `default`
        // Displays a title on the leading side and a secondary value on the trailing side
        case value1
        // Displays a title with a smaller subtitle below
        case subtitle
        // Displays the custom app logos cell
        case appLogos
    }
}
