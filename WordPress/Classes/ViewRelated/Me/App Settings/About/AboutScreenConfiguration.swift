import Foundation

typealias AboutScreenSection = [AboutItem]
typealias AboutScreenURLPresenterBlock = ((URL, AboutItemActionContext) -> Void)

/// Users of UnifiedAboutViewController must provide a configuration conforming to this protocol.
protocol AboutScreenConfiguration {
    /// A list of AboutItems, grouped into sections, which will be displayed in the about screen's table view.
    var sections: [AboutScreenSection] { get }

    /// A block that presents the provided URL in a web view
    var presentURLBlock: AboutScreenURLPresenterBlock? { get }

    /// A block that dismisses the about screen
    var dismissBlock: ((AboutItemActionContext) -> Void) { get }
}

typealias AboutItemAction = ((AboutItemActionContext) -> Void)

struct AboutItemActionContext {
    /// The About Screen view controller itself.
    let viewController: UIViewController

    /// If the action was triggered by the user interacting with a specific view, it'll be available here.
    let sourceView: UIView?

    init(viewController: UIViewController, sourceView: UIView? = nil) {
        self.viewController = viewController
        self.sourceView = sourceView
    }
}

/// An About Screen link contains a display title and url for a single link-based navigation item.
struct AboutScreenLink {
    let title: String
    let url: String

    init(_ title: String = "", url: String) {
        self.title = title
        self.url = url
    }
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

    /// An optional list of titles and URLs to be used for navigation.
    /// If a single link is provided, the title is ignored in favour of the item's title, and tapping the item's table row will display the URL in a webview.
    /// If multiple links are provided, an intermediary screen will be displayed containing a list of titles of each link.
    /// If a title on this intermediary screen is tapped, the associated URL will be displayed in a webview.
    let links: [AboutScreenLink]?

    init(title: String, subtitle: String? = nil, cellStyle: AboutItemCellStyle = .default, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, hidesSeparator: Bool = false, action: AboutItemAction? = nil, links: [AboutScreenLink]? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.cellStyle = cellStyle
        self.accessoryType = accessoryType
        self.hidesSeparator = hidesSeparator
        self.action = action
        self.links = links
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
