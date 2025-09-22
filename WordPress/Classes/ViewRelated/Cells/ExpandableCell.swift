import UIKit
import WordPressShared
import Gridicons
import CoreGraphics
import WordPressUI

class ExpandableCell: WPReusableTableViewCell, NibLoadable {

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
                transform = CGAffineTransform.identity
                alpha = 0
            }

            UIView.animate(withDuration: 0.2) {
                self.chevronImageView?.transform = transform
                self.expandableTextView?.alpha = alpha
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupSubviews()
    }

    public func toggle() {
        expanded = !expanded
    }

    private func setupSubviews() {
        chevronImageView?.image = .gridicon(.chevronDown)
        chevronImageView?.tintColor = WPStyleGuide.cellGridiconAccessoryColor()

        titleTextLabel?.textColor = .label

        let linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIAppColor.primary,
                                                             .underlineStyle: 0,
                                                             .underlineColor: UIColor.clear]
        expandableTextView?.linkTextAttributes = linkAttributes

        expandableTextView?.delegate = self
        expandableTextView?.textContainerInset = .zero
        expandableTextView?.textContainer.lineFragmentPadding = 0
        expandableTextView?.backgroundColor = .clear
    }

}

extension ExpandableCell: UITextViewDelegate {
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case let .link(URL) = textItem.content else {
            return defaultAction
        }

        return UIAction { [weak self] _ in
            self?.urlCallback?(URL)
        }
    }

    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        if case .link = textItem.content {
            return nil
        }

        return .init(menu: defaultMenu)
    }
}
