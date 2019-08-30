import Foundation
import WordPressShared.WPStyleGuide

open class ReaderBlockedSiteCell: UITableViewCell {
    @IBOutlet fileprivate weak var borderedContentView: UIView!
    @IBOutlet fileprivate weak var label: UILabel!

    open override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    fileprivate func applyStyles() {
        contentView.backgroundColor = .listBackground
        borderedContentView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedContentView.layer.borderWidth = .hairlineBorderWidth
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = .textSubtle
    }

    @objc open func setSiteName(_ name: String) {
        let format = NSLocalizedString("The site %@ will no longer appear in your reader. Tap to undo.",
            comment: "Message expliaining that the specified site will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the site.")
        let str = NSString(format: format as NSString, name)
        let range = str.range(of: name)

        let rawAttributes = WPStyleGuide.subtitleAttributes() as! [String: Any]
        let rawBoldAttributes = WPStyleGuide.subtitleAttributesBold() as! [String: Any]

        let swiftedAttributes = NSAttributedString.Key.convertFromRaw(attributes: rawAttributes)
        let swiftedBoldAttributes = NSAttributedString.Key.convertFromRaw(attributes: rawBoldAttributes)

        let attrStr = NSMutableAttributedString(string: str as String, attributes: swiftedAttributes)
        attrStr.setAttributes(swiftedBoldAttributes, range: range)
        label.attributedText = attrStr
    }

}
