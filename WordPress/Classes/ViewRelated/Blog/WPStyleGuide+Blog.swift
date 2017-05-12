import Foundation
import WordPressShared

extension WPStyleGuide {
    public class func configureTableViewBlogCell(_ cell: UITableViewCell) {
        cell.textLabel?.font = tableviewTextFont()
        cell.textLabel?.sizeToFit()
        cell.textLabel?.textColor = darkGrey()

        cell.detailTextLabel?.font = self.subtitleFont()
        cell.detailTextLabel?.sizeToFit()
        cell.detailTextLabel?.textColor = self.greyDarken10()

        cell.imageView?.layer.borderColor = UIColor.white.cgColor
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.tintColor = greyLighten10()

        cell.backgroundColor = UIColor.white
    }

    public class func configureCellForLogin(_ cell: WPBlogTableViewCell) {
        // TODO: make this dynamic size once @elibud's dynamic type code is merged
        cell.textLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        cell.textLabel?.sizeToFit()
        cell.textLabel?.textColor = darkGrey()

        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        cell.detailTextLabel?.sizeToFit()
        cell.detailTextLabel?.textColor = self.darkGrey()

        cell.imageView?.layer.borderColor = greyLighten20().cgColor
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.tintColor = greyLighten10()

        cell.backgroundColor = lightGrey()
    }

    public class func cellGridiconAccessoryColor() -> UIColor {
        return UIColor(red: 200.0 / 255.0, green: 200.0 / 255.0, blue: 205.0 / 255.0, alpha: 1.0)
    }
}
