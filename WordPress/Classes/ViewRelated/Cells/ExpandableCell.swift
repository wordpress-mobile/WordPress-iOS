import UIKit
import WordPressUIKit.WPStyleGuide
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

    public var urlCallback: ((URL) -> Void)?

    public var expanded: Bool = false {
        didSet {
            self.expandedTextLabel?.isHidden = !self.expanded

            let transform: CGAffineTransform
            let alpha: CGFloat

            if self.expanded {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                alpha = 1
            } else {
                transform =  CGAffineTransform.identity
                alpha = 0
            }

            UIView.animate(withDuration: 0.2) { [unowned self] in
                self.chevronImageView?.transform = transform
                self.expandedTextLabel?.alpha = alpha
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
        expandedTextLabel?.delegate = self
    }

}

extension ExpandableCell: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        urlCallback?(url)
    }
}
