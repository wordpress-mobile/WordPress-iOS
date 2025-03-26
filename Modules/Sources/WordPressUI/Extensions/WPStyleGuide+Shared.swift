import UIKit
import DesignSystem
import WordPressShared

extension WPStyleGuide {
    @objc(configureColorsForView:andTableView:)
    public class func configureColors(view: UIView?, tableView: UITableView?) {
        configureTableViewColors(view: view)
        configureTableViewColors(tableView: tableView)
    }

    public class func configureTableViewColors(view: UIView?) {
        guard let view else {
            return
        }
        view.backgroundColor = .systemBackground
    }

    public class func configureTableViewColors(tableView: UITableView?) {
        guard let tableView else {
            return
        }

        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = UIAppColor.neutral(.shade10)
    }

    @objc
    public class func configureTableViewSectionFooter(_ footer: UIView) {
        guard let footer = footer as? UITableViewHeaderFooterView,
            let textLabel = footer.textLabel else {
            return
        }
        if textLabel.isUserInteractionEnabled {
            textLabel.textColor = UIAppColor.primary
        }
    }
}
