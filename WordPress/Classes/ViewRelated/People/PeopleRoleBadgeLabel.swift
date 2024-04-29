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
        adjustsFontSizeToFitWidth = true
        horizontalPadding = WPStyleGuide.People.RoleBadge.horizontalPadding
        verticalPadding = WPStyleGuide.People.RoleBadge.verticalPadding
        font = WPStyleGuide.People.RoleBadge.font
        layer.cornerRadius = WPStyleGuide.People.RoleBadge.cornerRadius
    }
}
