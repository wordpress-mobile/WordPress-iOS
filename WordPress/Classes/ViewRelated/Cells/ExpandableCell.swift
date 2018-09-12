import UIKit
import WordPressShared.WPStyleGuide
import Gridicons
import CoreGraphics

class ExpandableCell: WPReusableTableViewCell {

    // MARK: - Initializers

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSubviews()
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    @IBOutlet var titleTextLabel: UILabel?
    @IBOutlet var expandableTextView: UITextView!
    @IBOutlet var chevronImageView: UIImageView?

    public var urlCallback: ((URL) -> Void)?

    public var expanded: Bool = false {
        didSet {
            self.expandableTextView?.isHidden = !self.expanded

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
                self.expandableTextView?.alpha = alpha
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
        expandableTextView?.linkTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: WPStyleGuide.wordPressBlue(),
                                                  NSAttributedString.Key.underlineStyle.rawValue: 0,
                                                  NSAttributedString.Key.underlineColor.rawValue: UIColor.clear])

        expandableTextView?.delegate = self
        expandableTextView?.textContainerInset = .zero
        expandableTextView?.textContainer.lineFragmentPadding = 0
    }

}

extension ExpandableCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            urlCallback?(URL)
            return false
        case .preview, .presentActions:
            return true
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
