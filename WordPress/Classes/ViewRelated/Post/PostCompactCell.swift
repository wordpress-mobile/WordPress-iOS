import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var badgesLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!

    static var height: CGFloat = 60

    func configure(with post: Post) {

    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.configureLabel(timestampLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: UIFont.TextStyle.subheadline)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(UIFont.TextStyle.headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = WPStyleGuide.darkGrey()
        timestampLabel.textColor = WPStyleGuide.grey()
        badgesLabel.textColor = WPStyleGuide.darkYellow()
        menuButton.tintColor = WPStyleGuide.greyLighten10()

        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        backgroundColor = WPStyleGuide.greyLighten30()
        contentView.backgroundColor = WPStyleGuide.greyLighten30()

        featuredImageView.layer.cornerRadius = 2
    }
}

extension PostCompactCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        
    }
}
