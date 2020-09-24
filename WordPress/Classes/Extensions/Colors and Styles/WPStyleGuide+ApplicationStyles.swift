import Foundation
import WordPressShared

extension WPStyleGuide {
    @objc
    public class var preferredStatusBarStyle: UIStatusBarStyle {
        if FeatureFlag.newNavBarAppearance.enabled {
            return .default
        }

        return .lightContent
    }

    @objc
    public class var navigationBarStandardFont: UIFont {
        return WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    }

    @objc
    public class var navigationBarLargeFont: UIFont {
        return WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    }

    // MARK: - styles used before Muriel colors are enabled
    public class func navigationBarBackgroundImage() -> UIImage {
        return UIImage(color: WPStyleGuide.wordPressBlue())
    }

    public class func navigationBarBarStyle() -> UIBarStyle {
        return .black
    }

    public class func navigationBarShadowImage() -> UIImage {
        return UIImage(color: UIColor(fromHex: 0x007eb1))
    }

    class func configureDefaultTint() {
        UIWindow.appearance().tintColor = .primary
    }

    /// Style the navigation appearance using Muriel colors
    class func configureNavigationAppearance() {
        let navigationAppearance = UINavigationBar.appearance()
        navigationAppearance.isTranslucent = false
        navigationAppearance.tintColor = .appBarTint
        navigationAppearance.barTintColor = .appBarBackground
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor.appBarText]

        var textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.appBarText]
        if FeatureFlag.newNavBarAppearance.enabled {
            textAttributes[.font] = WPStyleGuide.navigationBarStandardFont
        }

        navigationAppearance.titleTextAttributes = textAttributes

        if #available(iOS 13.0, *) {
            // Required to fix detail navigation controller appearance due to https://stackoverflow.com/q/56615513
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .appBarBackground
            appearance.titleTextAttributes = textAttributes

            navigationAppearance.standardAppearance = appearance
            navigationAppearance.scrollEdgeAppearance = navigationAppearance.standardAppearance
        }

        // Makes bar buttons visible in "Other Apps" media source picker.
        // Setting title text attributes makes bar button items not go blank when switching between the tabs of the picker.
        if FeatureFlag.newNavBarAppearance.enabled {
            let buttonBarAppearance = UIBarButtonItem.appearance()
            buttonBarAppearance.tintColor = .appBarTint
        } else {
            navigationAppearance.barStyle = .black

            let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIDocumentBrowserViewController.self])
            barButtonItemAppearance.tintColor = .barButtonItemTitle
            barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.barButtonItemTitle], for: .normal)

            let buttonBarAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
            buttonBarAppearance.tintColor = .white
            buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                        NSAttributedString.Key.foregroundColor: UIColor.white],
                                                       for: .normal)
            buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                        NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.25)],
                                                       for: .disabled)
        }
    }

    /// Style the tab bar using Muriel colors
    class func configureTabBarAppearance() {
        UITabBar.appearance().tintColor = .primary
        UITabBar.appearance().unselectedItemTintColor = .tabUnselected
    }

    /// Style the `LightNavigationController` UINavigationBar and BarButtonItems
    class func configureLightNavigationBarAppearance() {
        let separatorColor: UIColor

        if #available(iOS 13.0, *) {
            separatorColor = .systemGray4
        } else {
            separatorColor = .lightGray
        }

        let navigationBarAppearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [LightNavigationController.self])
        navigationBarAppearanceProxy.backgroundColor = .white // Only used on iOS 12 so doesn't need dark mode support
        navigationBarAppearanceProxy.barStyle = .default
        navigationBarAppearanceProxy.barTintColor = .white

        navigationBarAppearanceProxy.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.text
        ]

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = separatorColor
            navigationBarAppearanceProxy.standardAppearance = appearance
        }

        let tintColor = UIColor(light: .brand, dark: .white)

        let buttonBarAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [LightNavigationController.self])
        buttonBarAppearance.tintColor = tintColor
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor],
                                                   for: .normal)
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor.withAlphaComponent(0.25)],
                                                   for: .disabled)

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
