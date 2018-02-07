import Foundation
import WordPressUIKit.WPStyleGuide

open class ReaderBlockedSiteCell: UITableViewCell {
    @IBOutlet fileprivate weak var borderedContentView: UIView!
    @IBOutlet fileprivate weak var label: UILabel!

    open override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    fileprivate func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedContentView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedContentView.layer.borderWidth = 1.0
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = WPStyleGuide.whisperGrey()
    }

    @objc open func setSiteName(_ name: String) {
        let format = NSLocalizedString("The site %@ will no longer appear in your reader. Tap to undo.",
            comment: "Message expliaining that the specified site will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the site.")
        let str = NSString(format: format as NSString, name)
        let range = str.range(of: name)

        let rawAttributes = WPStyleGuide.subtitleAttributes() as! [String: Any]
        let rawBoldAttributes = WPStyleGuide.subtitleAttributesBold() as! [String: Any]

        let swiftedAttributes = NSAttributedStringKey.convertFromRaw(attributes: rawAttributes)
        let swiftedBoldAttributes = NSAttributedStringKey.convertFromRaw(attributes: rawBoldAttributes)

        let attrStr = NSMutableAttributedString(string: str as String, attributes: swiftedAttributes)
        attrStr.setAttributes(swiftedBoldAttributes, range: range)
        label.attributedText = attrStr
    }

}
