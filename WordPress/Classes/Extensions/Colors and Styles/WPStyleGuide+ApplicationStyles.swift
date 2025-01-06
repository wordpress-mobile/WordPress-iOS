import Foundation
import UIKit
import WordPressShared
import WordPressUI

extension WPStyleGuide {

    public class func configureAppearance() {
        WPStyleGuide.configureNavigationAppearance()

        // iOS 14 started rendering backgrounds for stack views, when previous versions
        // of iOS didn't show them. This is a little hacky, but ensures things keep
        // looking the same on newer versions of iOS.
        UIStackView.appearance().backgroundColor = .clear

        UIWindow.appearance().tintColor = UIAppColor.primary
        UISwitch.appearance().onTintColor = UIAppColor.primary

        UITableView.appearance().sectionHeaderTopPadding = 0

        setupFancyAlertAppearance()
        setupFancyButtonAppearance()
    }

    public class var navigationBarStandardFont: UIFont {
        return AppStyleGuide.navigationBarStandardFont
    }

    /// Style the navigation appearance using Muriel colors
    private class func configureNavigationAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        configureSharedSettings(for: standardAppearance)

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        configureSharedSettings(for: scrollEdgeAppearance)

        let appearance = UINavigationBar.appearance()
        appearance.tintColor = UIAppColor.tint // Back button color

        appearance.standardAppearance = standardAppearance
        appearance.compactAppearance = standardAppearance
        appearance.scrollEdgeAppearance = scrollEdgeAppearance
        appearance.compactScrollEdgeAppearance = scrollEdgeAppearance
    }

    private class func configureSharedSettings(for appearance: UINavigationBarAppearance) {
        appearance.titleTextAttributes = [
            .font: WPStyleGuide.navigationBarStandardFont,
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .font: AppStyleGuide.navigationBarLargeFont
        ]
    }

    class func disableScrollEdgeAppearance(for viewController: UIViewController) {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        configureSharedSettings(for: standardAppearance)

        viewController.navigationItem.scrollEdgeAppearance = standardAppearance
        viewController.navigationItem.compactScrollEdgeAppearance = standardAppearance
    }

    @objc class func configureTabBar(_ tabBar: UITabBar) {
        tabBar.tintColor = UIAppColor.tint
        tabBar.unselectedItemTintColor = UIColor(named: "TabUnselected")
    }

    private static func setupFancyAlertAppearance() {
        let appearance = FancyAlertView.appearance()

        appearance.titleTextColor = UIAppColor.neutral(.shade70)
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)

        appearance.bodyTextColor = UIAppColor.neutral(.shade70)
        appearance.bodyFont = WPStyleGuide.fontForTextStyle(.body)
        appearance.bodyBackgroundColor = UIAppColor.neutral(.shade0)

        appearance.actionFont = WPStyleGuide.fontForTextStyle(.headline)
        appearance.infoFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        appearance.infoTintColor = UIAppColor.primary

        appearance.topDividerColor = UIAppColor.neutral(.shade5)
        appearance.bottomDividerColor = UIAppColor.neutral(.shade0)
        appearance.headerBackgroundColor = UIAppColor.neutral(.shade0)

        appearance.bottomBackgroundColor = UIAppColor.neutral(.shade0)
    }

    private static func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.titleFont = WPStyleGuide.fontForTextStyle(.headline)
        appearance.primaryTitleColor = .white
        appearance.primaryNormalBackgroundColor = UIAppColor.primary
        appearance.primaryHighlightBackgroundColor = UIAppColor.primary(.shade80)

        appearance.secondaryTitleColor = .label
        appearance.secondaryNormalBackgroundColor = UIColor(light: .white, dark: .systemGray5)
        appearance.secondaryNormalBorderColor = .systemGray3
        appearance.secondaryHighlightBackgroundColor = .systemGray3
        appearance.secondaryHighlightBorderColor = .systemGray3

        appearance.disabledTitleColor = UIAppColor.neutral(.shade20)
        appearance.disabledBackgroundColor = UIColor(light: .white, dark: UIAppColor.gray(.shade100))
        appearance.disabledBorderColor = UIAppColor.neutral(.shade10)
    }
}

extension WPStyleGuide {
    @objc(configureColorsForView:andTableView:)
    open class func configureColors(view: UIView?, tableView: UITableView?) {
        configureTableViewColors(view: view)
        configureTableViewColors(tableView: tableView)
    }

    class func configureTableViewColors(view: UIView?) {
        guard let view else {
            return
        }
        view.backgroundColor = .systemBackground
    }

    class func configureTableViewColors(tableView: UITableView?) {
        guard let tableView else {
            return
        }

        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = UIAppColor.neutral(.shade10)
    }

    class func configureColors(view: UIView, collectionView: UICollectionView) {
        configureTableViewColors(view: view)
        collectionView.backgroundView = nil
        collectionView.backgroundColor = .systemGroupedBackground
    }

    @objc
    class func configureTableViewCell(_ cell: UITableViewCell?) {
        guard let cell else {
            return
        }

        cell.textLabel?.font = tableviewTextFont()
        cell.textLabel?.sizeToFit()
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .callout)
        cell.detailTextLabel?.sizeToFit()

        // we only set the text subtle color, so that system colors are used otherwise
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.tintColor = UIAppColor.neutral(.shade30)

    }

    class func configureTableViewSmallSubtitleCell(_ cell: UITableViewCell) {
        configureTableViewColors(view: cell)
        cell.detailTextLabel?.font = subtitleFont()
        cell.detailTextLabel?.textColor = .secondaryLabel
    }

    @objc
    class func configureTableViewActionCell(_ cell: UITableViewCell?) {
        configureTableViewCell(cell)
        cell?.textLabel?.textColor = UIAppColor.primary
    }

    @objc
    class func configureTableViewDestructiveActionCell(_ cell: UITableViewCell) {
        configureTableViewCell(cell)

        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = UIAppColor.error
    }

    @objc
    class func configureTableViewSectionFooter(_ footer: UIView) {
        guard let footer = footer as? UITableViewHeaderFooterView,
            let textLabel = footer.textLabel else {
            return
        }
        if textLabel.isUserInteractionEnabled {
            textLabel.textColor = UIAppColor.primary
        }
    }
}
