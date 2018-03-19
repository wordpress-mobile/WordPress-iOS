import UIKit

/// A subclass of BlogDetailHeaderView styled for use in the login flow.
///
class SiteInfoHeaderView: BlogDetailHeaderView {


    override func awakeFromNib() {
        super.awakeFromNib()

        configureStyles()
    }


    @objc func configureStyles() {

        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        titleLabel.textColor = WPStyleGuide.darkGrey()

        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        subtitleLabel.textColor = WPStyleGuide.darkGrey()

        blavatarImageView.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        blavatarImageView.layer.borderWidth = 1
        blavatarImageView.tintColor = WPStyleGuide.greyLighten10()
    }

}

extension SiteInfoHeaderView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureStyles()
        }
    }
}
