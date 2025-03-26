import Foundation
import WordPressShared

open class ReaderBlockedSiteCell: UITableViewCell {
    @IBOutlet fileprivate weak var borderedContentView: UIView!
    @IBOutlet fileprivate weak var label: UILabel!

    open override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    fileprivate func applyStyles() {
        contentView.backgroundColor = .systemGroupedBackground
        borderedContentView.layer.borderColor = UIColor.separator.cgColor
        borderedContentView.layer.borderWidth = .hairlineBorderWidth
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = .secondaryLabel
    }

    @objc open func setSiteName(_ name: String) {
        let format = NSLocalizedString(
            "reader.blocked.blog.message",
            value: "The blog %@ will no longer appear in your reader. Tap to undo.",
            comment: "Message expliaining that the specified blog will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the blog."
        )
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

private extension NSAttributedString.Key {
    /// Converts a collection of NSAttributedString Attributes, with 'String' instances as 'Keys', into an equivalent
    /// collection that uses the new 'NSAttributedStringKey' enum as keys.
    ///
    static func convertFromRaw(attributes: [String: Any]) -> [NSAttributedString.Key: Any] {
        var output = [NSAttributedString.Key: Any]()
        for (key, value) in attributes {
            let wrappedKey = NSAttributedString.Key(key)
            output[wrappedKey] = value
        }

        return output
    }
}
