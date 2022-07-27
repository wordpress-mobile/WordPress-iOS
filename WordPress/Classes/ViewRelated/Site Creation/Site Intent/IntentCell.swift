import UIKit

final class IntentCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var emojiContainer: UIView!
    @IBOutlet weak var emoji: UILabel!

    static var estimatedSize: CGSize {
        return CGSize(width: 320, height: 63)
    }

    var model: SiteIntentVertical? {
        didSet {
            title.text = model?.localizedTitle
            emoji.text = model?.emoji
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        selectedBackgroundView?.backgroundColor = .clear

        accessibilityTraits = .button
        accessibilityHint = NSLocalizedString("Selects this topic as the intent for your site.",
                                              comment: "Accessibility hint for a topic in the Site Creation intents view.")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        emojiContainer.layer.cornerRadius = emojiContainer.layer.frame.width / 2
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
    }

    override func prepareForReuse() {
        title.text = nil
        emoji.text = nil
    }
}
