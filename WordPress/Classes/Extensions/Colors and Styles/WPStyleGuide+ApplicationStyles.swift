import Foundation
import UIKit
import WordPressShared

extension WPStyleGuide {

    public class func configureAppearance() {
        WPStyleGuide.configureNavigationAppearance()

        // iOS 14 started rendering backgrounds for stack views, when previous versions
        // of iOS didn't show them. This is a little hacky, but ensures things keep
        // looking the same on newer versions of iOS.
        UIStackView.appearance().backgroundColor = .clear

        UIWindow.appearance().tintColor = .primary
        UISwitch.appearance().onTintColor = .primary

        UITableView.appearance().sectionHeaderTopPadding = 0
    }

    public class var navigationBarStandardFont: UIFont {
        return AppStyleGuide.navigationBarStandardFont
    }

    /// Style the navigation appearance using Muriel colors
    private class func configureNavigationAppearance() {
        var textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.appBarText]
        let largeTitleTextAttributes: [NSAttributedString.Key: Any] = [.font: AppStyleGuide.navigationBarLargeFont]

        textAttributes[.font] = WPStyleGuide.navigationBarStandardFont

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.titleTextAttributes = textAttributes
        standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = textAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = largeTitleTextAttributes

        let appearance = UINavigationBar.appearance()
        appearance.tintColor = .appBarTint

        appearance.standardAppearance = standardAppearance
        appearance.compactAppearance = standardAppearance
        appearance.scrollEdgeAppearance = scrollEdgeAppearance
        appearance.compactScrollEdgeAppearance = scrollEdgeAppearance
    }
}

extension WPStyleGuide {
    @objc(configureColorsForView:andTableView:)
    open class func configureColors(view: UIView?, tableView: UITableView?) {
        configureTableViewColors(view: view)
        configureTableViewColors(tableView: tableView)
    }

    class func configureTableViewColors(view: UIView?) {
        guard let view = view else {
            return
        }
        view.backgroundColor = .basicBackground
    }

    class func configureTableViewColors(tableView: UITableView?) {
        guard let tableView = tableView else {
            return
        }

        tableView.backgroundColor = .listBackground
        tableView.separatorColor = .neutral(.shade10)
    }

    class func configureColors(view: UIView, collectionView: UICollectionView) {
        configureTableViewColors(view: view)
        collectionView.backgroundView = nil
        collectionView.backgroundColor = .listBackground
    }

    @objc
    class func configureTableViewCell(_ cell: UITableViewCell?) {
        guard let cell = cell else {
            return
        }

        cell.textLabel?.font = tableviewTextFont()
        cell.textLabel?.sizeToFit()
        cell.detailTextLabel?.font = tableviewSubtitleFont()
        cell.detailTextLabel?.sizeToFit()

        // we only set the text subtle color, so that system colors are used otherwise
        cell.detailTextLabel?.textColor = .textSubtle
        cell.imageView?.tintColor = .neutral(.shade30)

    }

    class func configureTableViewSmallSubtitleCell(_ cell: UITableViewCell) {
        configureTableViewColors(view: cell)
        cell.detailTextLabel?.font = subtitleFont()
        cell.detailTextLabel?.textColor = .textSubtle
    }

    @objc
    class func configureTableViewActionCell(_ cell: UITableViewCell?) {
        configureTableViewCell(cell)
        cell?.textLabel?.textColor = .text
    }

    @objc
    class func configureTableViewDestructiveActionCell(_ cell: UITableViewCell) {
        configureTableViewCell(cell)

        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = UIColor.error
    }

    @objc
    class func configureTableViewTextCell(_ cell: WPTextFieldTableViewCell) {
        configureTableViewCell(cell)

        if cell.textField.isEnabled {
            cell.detailTextLabel?.textColor = .text
            cell.textField.textAlignment = .natural
        } else {
            cell.detailTextLabel?.textColor = .textSubtle
            if cell.effectiveUserInterfaceLayoutDirection == .leftToRight {
                // swiftlint:disable:next inverse_text_alignment
                cell.textField.textAlignment = .right
            } else {
                // swiftlint:disable:next natural_text_alignment
                cell.textField.textAlignment = .left
            }
        }
    }

    @objc
    class func configureTableViewSectionFooter(_ footer: UIView) {
        guard let footer = footer as? UITableViewHeaderFooterView,
            let textLabel = footer.textLabel else {
            return
        }
        if textLabel.isUserInteractionEnabled {
            textLabel.textColor = .primary
        }
    }

}
