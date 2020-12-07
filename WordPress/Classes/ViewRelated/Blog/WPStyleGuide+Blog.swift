import Foundation
import WordPressShared

extension WPStyleGuide {
    @objc public class func configureTableViewBlogCell(_ cell: UITableViewCell) {
        cell.textLabel?.font = tableviewTextFont()
        cell.textLabel?.sizeToFit()
        cell.textLabel?.textColor = .text

        cell.detailTextLabel?.font = self.subtitleFont()
        cell.detailTextLabel?.sizeToFit()
        cell.detailTextLabel?.textColor = .textSubtle

        cell.imageView?.layer.borderColor = UIColor.divider.cgColor
        cell.imageView?.layer.borderWidth = .hairlineBorderWidth
        cell.imageView?.tintColor = .listIcon

        cell.backgroundColor = UIColor.listForeground
    }

    @objc public class func configureCellForLogin(_ cell: WPBlogTableViewCell) {
        cell.textLabel?.textColor = .text
        cell.detailTextLabel?.textColor = .textSubtle

        let fontSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        cell.textLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)

        cell.imageView?.tintColor = .listIcon

        cell.selectionStyle = .none
        cell.backgroundColor = .basicBackground
    }

}

extension LoginEpilogueBlogCell {
    // Per Apple's documentation (https://developer.apple.com/documentation/xcode/supporting_dark_mode_in_your_interface),
    // `cgColor` objects do not adapt to appearance changes (i.e. toggling light/dark mode).
    // `tintColorDidChange` is called when the appearance changes, so re-set the border color when this occurs.
    override func tintColorDidChange() {
        super.tintColorDidChange()
        imageView?.layer.borderColor = UIColor.neutral(.shade10).cgColor
    }
}
