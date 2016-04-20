import UIKit
import WordPressShared.WPStyleGuide

@IBDesignable
class PeopleRoleBadgeView: UILabel {

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        font = WPStyleGuide.People.RoleBadge.font
        textAlignment = .Center
        layer.borderWidth = WPStyleGuide.People.RoleBadge.borderWidth
        layer.cornerRadius = WPStyleGuide.People.RoleBadge.cornerRadius
        layer.masksToBounds = true
    }

    // MARK: Padding

    override func drawTextInRect(rect: CGRect) {
        let padding = WPStyleGuide.People.RoleBadge.padding
        let insets = UIEdgeInsetsMake(0, padding, 0, padding)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }

    override func intrinsicContentSize() -> CGSize {
        var paddedSize = super.intrinsicContentSize()
        paddedSize.width += 2 * WPStyleGuide.People.RoleBadge.padding
        return paddedSize
    }

    //  MARK: Computed Properties

    var borderColor: UIColor {
        get {
            return UIColor(CGColor: layer.borderColor!)
        }

        set {
            layer.borderColor = newValue.CGColor
        }
    }
}
