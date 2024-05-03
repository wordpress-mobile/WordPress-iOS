import UIKit
import DesignSystem

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
        horizontalPadding = CGFloat.DS.Padding.single
        verticalPadding = .DS.Padding.half
        font = .DS.font(.footnote)
        layer.cornerRadius = .DS.Radius.small
    }
}
