import Foundation
import WordPressShared.WPStyleGuide

public class ReaderBlockedSiteCell: UITableViewCell
{
    @IBOutlet private weak var borderedContentView: UIView!
    @IBOutlet private weak var label: UILabel!

    public override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedContentView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().CGColor
        borderedContentView.layer.borderWidth = 1.0
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = WPStyleGuide.whisperGrey()
    }

    public func setSiteName(name:String) {
        let format = NSLocalizedString("The site %@ will no longer appear in your reader. Tap to undo.",
            comment:"Message expliaining that the specified site will no longer appear in the user's reader.  The '%@' characters are a placeholder for the title of the site.")
        let str = NSString(format: format, name)
        let range = str.rangeOfString(name)

        let attributes = WPStyleGuide.subtitleAttributes()
        let boldAttributes = WPStyleGuide.subtitleAttributesBold()

        let attrStr = NSMutableAttributedString(string: str as String, attributes: attributes as? [String:AnyObject])
        attrStr.setAttributes(boldAttributes as? [String:AnyObject], range: range)
        label.attributedText = attrStr
    }

}
