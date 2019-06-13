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

    // MARK: - style the navigation appearance using Muriel colors
    class func configureNavigationAppearance() {
        let navigationAppearance = UINavigationBar.appearance()
        navigationAppearance.isTranslucent = false
        navigationAppearance.barTintColor = .navigationBar
        navigationAppearance.barStyle = .black

        let buttonBarAppearance = UIBarButtonItem.appearance()
        buttonBarAppearance.tintColor = .white
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: UIColor.white],
                                                   for: .normal)
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: UIColor(white: 1.0, alpha: 0.25)],
                                                   for: .disabled)

    }
}


extension WPStyleGuide {
    @objc(configureColorsForView:andTableView:)
    open class func configureColors(view: UIView?, tableView: UITableView?) {
        
    }

    class func configureColors(view: UIView, collectionView: UICollectionView) {
    }

    @objc
    class func configureTableViewCell(_ cell: UITableViewCell?) {
        guard let cell = cell else {
            return
        }

    }

    class func configureTableViewSmallSubtitleCell(_ cell: UITableViewCell) {
    }

    @objc
    class func configureTableViewActionCell(_ cell: UITableViewCell?) {
        guard let cell = cell else {
            return
        }
    }

    @objc
    class func configureTableViewDestructiveActionCell(_ cell: UITableViewCell) {
    }

    @objc
    class func configureTableViewTextCell(_ cell: WPTextFieldTableViewCell) {

    }

    @objc class func configureTableViewSectionHeader(_ header: UIView) {
        guard let header = header as? UITableViewHeaderFooterView else {
            return
        }

    }

    @objc
    class func configureTableViewSectionFooter(_ footer: UIView) {
        guard let footer = footer as? UITableViewHeaderFooterView else {
            return
        }

    }

}
