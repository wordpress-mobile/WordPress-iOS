import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var badgesLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var labelsLeadingConstraint: NSLayoutConstraint!

    static var height: CGFloat = 60

    func configure(with post: Post) {

    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        setupReadableGuideForiPad()
    }

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.configureLabel(timestampLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.applyPostProgressViewStyle(progressView)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(UIFont.TextStyle.headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = WPStyleGuide.darkGrey()
        timestampLabel.textColor = WPStyleGuide.grey()
        badgesLabel.textColor = WPStyleGuide.darkYellow()
        menuButton.tintColor = WPStyleGuide.greyLighten10()

        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        backgroundColor = WPStyleGuide.greyLighten30()

        featuredImageView.layer.cornerRadius = 2
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        innerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        labelsLeadingConstraint.constant = -8
    }
}

extension PostCompactCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        
    }
}
