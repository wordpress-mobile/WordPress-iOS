import Foundation
import WordPressShared

extension WPStyleGuide {
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
        guard FeatureFlag.murielColors.enabled else {
            configureNavigationBarAppearance()
            return
        }

        UIWindow.appearance().tintColor = .primary
    }

    /// Style the navigation appearance using Muriel colors
    class func configureNavigationAppearance() {
        guard FeatureFlag.murielColors.enabled else {
            configureNavigationBarAppearance()
            return
        }

        let navigationAppearance = UINavigationBar.appearance()
        navigationAppearance.isTranslucent = false
        navigationAppearance.tintColor = .textInverted
        navigationAppearance.barTintColor = .navigationBar
        navigationAppearance.barStyle = .black

#if XCODE11
        if #available(iOS 13.0, *) {
            // Required to fix detail navigation controller appearance due to https://stackoverflow.com/q/56615513
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .brand
            appearance.titleTextAttributes = [.foregroundColor: UIColor.textInverted]
            navigationAppearance.standardAppearance = appearance
            navigationAppearance.scrollEdgeAppearance = navigationAppearance.standardAppearance
        }
#endif

        let buttonBarAppearance = UIBarButtonItem.appearance()
        buttonBarAppearance.tintColor = .textInverted
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: UIColor.textInverted],
                                                   for: .normal)
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: UIColor.textInverted.withAlphaComponent(0.25)],
                                                   for: .disabled)
    }

    /// Style the tab bar using Muriel colors
    class func configureTabBarAppearance() {
        UITabBar.appearance().tintColor = .primary
        UITabBar.appearance().unselectedItemTintColor = .unselected
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
        if !FeatureFlag.murielColors.enabled {
            view.backgroundColor = greyLighten30()
        }
    }
    class func configureTableViewColors(tableView: UITableView?) {
        guard let tableView = tableView else {
            return
        }
        if FeatureFlag.murielColors.enabled {
            tableView.backgroundColor = .tableBackground
            tableView.separatorColor = .neutral(shade: .shade10)
        } else {
            tableView.backgroundView = nil
            tableView.backgroundColor = greyLighten30()
            tableView.separatorColor = greyLighten20()
        }
    }

    class func configureColors(view: UIView, collectionView: UICollectionView) {
        configureTableViewColors(view: view)
        collectionView.backgroundView = nil
        collectionView.backgroundColor = greyLighten30()
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
        if FeatureFlag.murielColors.enabled {
            cell.detailTextLabel?.textColor = .textSubtle
            cell.imageView?.tintColor = .neutral(shade: .shade30)
        } else {
            cell.textLabel?.textColor = darkGrey()
            cell.detailTextLabel?.textColor = grey()
            cell.imageView?.tintColor = greyLighten10()
        }
    }

    class func configureTableViewSmallSubtitleCell(_ cell: UITableViewCell) {
        configureTableViewColors(view: cell)
        cell.detailTextLabel?.font = subtitleFont()
        if FeatureFlag.murielColors.enabled {
            cell.detailTextLabel?.textColor = .textSubtle
        } else {
            cell.detailTextLabel?.textColor = darkGrey()
        }
    }

    @objc
    class func configureTableViewActionCell(_ cell: UITableViewCell?) {
        configureTableViewCell(cell)
        cell?.textLabel?.textColor = .primary
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
            if FeatureFlag.murielColors.enabled {
                cell.detailTextLabel?.textColor = .text
            } else {
                cell.detailTextLabel?.textColor = darkBlue()
            }
            cell.textField.textAlignment = .natural
        } else {
            if FeatureFlag.murielColors.enabled {
                cell.detailTextLabel?.textColor = .textSubtle
            } else {
                cell.detailTextLabel?.textColor = darkGrey()
            }
            if cell.effectiveUserInterfaceLayoutDirection == .leftToRight {
                // swiftlint:disable:next inverse_text_alignment
                cell.textField.textAlignment = .right
            } else {
                // swiftlint:disable:next natural_text_alignment
                cell.textField.textAlignment = .left
            }
        }
    }

    @objc class func configureTableViewSectionHeader(_ header: UIView) {
        guard !FeatureFlag.murielColors.enabled,
            let header = header as? UITableViewHeaderFooterView else {
            return
        }
        header.textLabel?.textColor = whisperGrey()
    }

    @objc
    class func configureTableViewSectionFooter(_ footer: UIView) {
        guard let footer = footer as? UITableViewHeaderFooterView,
            let textLabel = footer.textLabel else {
            return
        }
        if textLabel.isUserInteractionEnabled {
            textLabel.textColor = .primary
        } else if !FeatureFlag.murielColors.enabled {
            textLabel.textColor = greyDarken10()
        }

    }

}
