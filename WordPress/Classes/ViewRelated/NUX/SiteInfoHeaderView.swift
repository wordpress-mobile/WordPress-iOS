import UIKit

/// A subclass of BlogDetailHeaderView styled for use in the login flow.
///
class SiteInfoHeaderView: BlogDetailHeaderView {


    override func awakeFromNib() {
        super.awakeFromNib()

        configureStyles()
    }


    func configureStyles() {

        titleLabel.font = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        titleLabel.sizeToFit()
        titleLabel.textColor = WPStyleGuide.darkGrey()

        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        subtitleLabel.sizeToFit()
        subtitleLabel.textColor = WPStyleGuide.darkGrey()

        blavatarImageView.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        blavatarImageView.layer.borderWidth = 1
        blavatarImageView.tintColor = WPStyleGuide.greyLighten10()
    }

}
