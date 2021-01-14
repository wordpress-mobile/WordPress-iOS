import UIKit
import WordPressShared.WPStyleGuide

class PeopleRoleBadgeLabel: BadgeLabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        adjustsFontForContentSizeCategory = true
        adjustsFontSizeToFitWidth = true
        horizontalPadding = WPStyleGuide.People.RoleBadge.padding
        font = WPStyleGuide.People.RoleBadge.font
        layer.borderWidth = WPStyleGuide.People.RoleBadge.borderWidth
        layer.cornerRadius = WPStyleGuide.People.RoleBadge.cornerRadius
    }
}
