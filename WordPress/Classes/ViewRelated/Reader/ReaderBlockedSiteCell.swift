import Foundation

 public class ReaderBlockedSiteCell: UITableViewCell
{

    @IBOutlet private weak var label: UILabel!

    public override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        label.font = WPStyleGuide.subtitleFont()
        label.textColor = WPStyleGuide.whisperGrey()
    }

    public func setLabelText(text:String) {
        label.text = text
    }

    public func setAttributedText(attributedText:NSAttributedString) {
        label.attributedText = attributedText
    }

}
