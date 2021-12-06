import UIKit
import WordPressUI

/// Provides a fallback implementation for showing `UIMenu` in iOS 13. To "mimic" the `UIContextMenu` appearance, this
/// view controller should be presented modally with a `.popover` presentation style. Note that to simplify things,
/// nested elements will be displayed as if `UIMenuOptions.displayInline` is applied.
///
/// In iOS 13, `UIMenu` can only appear through long press gesture. There is no way to make it appear programmatically
/// or through different gestures. However, in iOS 14 menus can be configured to appear on tap events. Refer to
/// `showsMenuAsPrimaryAction` for more details.
///
/// TODO: Remove this component (and its usage) in favor of `UIMenu` when the minimum version is bumped to iOS 14.
///
class MenuSheetViewController: UITableViewController {

    struct MenuItem {
        let title: String
        let image: UIImage?
        let handler: () -> Void
    }

    private let itemSource: [[MenuItem]]
    private let orientation: UIDeviceOrientation // used to track if orientation changes.

    // MARK: Lifecycle

    required init(items: [[MenuItem]]) {
        self.itemSource = items
        self.orientation = UIDevice.current.orientation

        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        preferredContentSize = CGSize(width: min(tableView.contentSize.width, Constants.maxWidth), height: tableView.contentSize.height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Dismiss the menu when the orientation changes. This mimics the behavior of UIContextMenu/UIMenu.
        if UIDevice.current.orientation != orientation {
            dismissMenu()
        }
    }

}

// MARK: - Table View

extension MenuSheetViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return itemSource.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = itemSource[safe: section] else {
            return 0
        }
        return items.count
    }

    /// Override separator color in dark mode so it kinda matches the separator color in `UIContextMenu`.
    /// With system colors, somehow dark colors won't go darker below the cell's background color.
    /// Note that returning nil means falling back to the default behavior.
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard traitCollection.userInterfaceStyle == .dark else {
            return nil
        }

        let headerView = UIView()
        headerView.backgroundColor = Constants.darkSeparatorColor
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? tableView.sectionHeaderHeight : Constants.tableSectionHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = itemSource[safe: indexPath.section],
              let item = items[safe: indexPath.row] else {
                  return .init()
              }

        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        cell.tintColor = .text
        cell.textLabel?.setText(item.title)
        cell.accessoryView = UIImageView(image: item.image?.withTintColor(.text))

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        dismissMenu {
            guard let items = self.itemSource[safe: indexPath.section],
                  let item = items[safe: indexPath.row] else {
                      return
                  }

            item.handler()
        }
    }
}

// MARK: - Private Helpers

private extension MenuSheetViewController {
    struct Constants {
        // maximum width follows the approximate width of `UIContextMenu`.
        static let maxWidth: CGFloat = 250
        static let tableSectionHeight: CGFloat = 8
        static let darkSeparatorColor = UIColor(fromRGBColorWithRed: 11, green: 11, blue: 11)
        static let cellIdentifier = "cell"
    }

    func configureTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.sectionHeaderHeight = 0

        // draw the separators from edge to edge.
        tableView.separatorInset = .zero

        // hide separators for the last row.
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0))
    }

    func dismissMenu(completion: (() -> Void)? = nil) {
        if let controller = popoverPresentationController {
            controller.delegate?.presentationControllerWillDismiss?(controller)
        }

        dismiss(animated: true) {
            defer {
                if let controller = self.popoverPresentationController {
                    controller.delegate?.presentationControllerDidDismiss?(controller)
                }
            }
            completion?()
        }
    }
}
