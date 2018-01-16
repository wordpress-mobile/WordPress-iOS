import UIKit
import WordPressShared.WPStyleGuide
import Gridicons
import TTTAttributedLabel
import CoreGraphics

class ExpandableCell: WPReusableTableViewCell {

    // MARK: - Initializers

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSubviews()
    }

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    @IBOutlet var titleTextLabel: UILabel?
    @IBOutlet var expandedTextLabel: TTTAttributedLabel?
    @IBOutlet var chevronImageView: UIImageView?

    public var expandedText: NSAttributedString?

    public var expanded: Bool = false {
        didSet {
            self.expandedTextLabel?.isHidden = !self.expanded

            let transform: CGAffineTransform
            if self.expanded {
                self.expandedTextLabel?.setText(self.expandedText)
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                self.expandedTextLabel?.setText(nil)
                transform =  CGAffineTransform.identity
            }

            UIView.animate(withDuration: 0.2) { [unowned self] in
                self.chevronImageView?.transform = transform
            }
        }
    }

    override func awakeFromNib() {
        setupSubviews()
    }

    public func toggle() {
        expanded = !expanded
    }

    private func setupSubviews() {
        chevronImageView?.image = Gridicon.iconOfType(.chevronDown)
        chevronImageView?.tintColor = WPStyleGuide.cellGridiconAccessoryColor()

        titleTextLabel?.textColor = WPStyleGuide.darkGrey()
        expandedTextLabel?.linkAttributes = [NSAttributedStringKey.foregroundColor: WPStyleGuide.wordPressBlue(),
                                             NSAttributedStringKey.underlineStyle: 0]
        expandedTextLabel?.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
    }
}
