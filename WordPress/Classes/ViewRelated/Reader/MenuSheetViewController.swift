import UIKit
import WordPressUI

/// Provides a fallback implementation for showing `UIMenu` in iOS 13. Instead of showing a floating menu, this embeds
/// the menu in a table view through `BottomSheetViewController`. Note that to simplify things, nested elements will be
/// displayed as if `UIMenuOptions.displayInline` is applied.
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

    // MARK: Lifecycle

    required init(items: [[MenuItem]]) {
        self.itemSource = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTable()
    }
}

// MARK: - Table View

extension MenuSheetViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return itemSource.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < itemSource.count else {
            return 0
        }
        return itemSource[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemSource[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)

        cell.textLabel?.setText(item.title)
        cell.accessoryView = UIImageView(image: item.image?.withTintColor(.text))
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = itemSource[indexPath.section][indexPath.row]
        dismiss(animated: true) {
            item.handler()
        }
    }
}

// MARK: - Drawer Presentable

extension MenuSheetViewController: DrawerPresentable {
    var allowsUserTransition: Bool {
        false
    }
}

// MARK: - Private Helpers

private extension MenuSheetViewController {
    struct Constants {
        static let cellIdentifier = "cell"
    }

    func configureTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)

        // hide separators for the last row.
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1))
    }
}
