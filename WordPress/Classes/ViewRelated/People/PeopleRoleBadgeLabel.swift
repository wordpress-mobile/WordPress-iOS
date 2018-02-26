import UIKit
import WordPressShared.WPStyleGuide

@IBDesignable
class PeopleRoleBadgeLabel: BadgeLabel {
    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    fileprivate func setupView() {
        adjustsFontForContentSizeCategory = true
        horizontalPadding = WPStyleGuide.People.RoleBadge.padding
        font = WPStyleGuide.People.RoleBadge.font
        layer.borderWidth = WPStyleGuide.People.RoleBadge.borderWidth
        layer.cornerRadius = WPStyleGuide.People.RoleBadge.cornerRadius
    }
}
