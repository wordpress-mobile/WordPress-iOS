import UIKit
import WordPressShared

open class WPHelpIndicatorView: UIView {

    struct Constants {
        static let defaultInsets = UIEdgeInsets.zero
        static let defaultBackgroundColor = WordPressAuthenticator.shared.style.navBarBadgeColor
    }

    var insets: UIEdgeInsets = Constants.defaultInsets {
        didSet {
            setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonSetup() {
        layer.masksToBounds = true
        layer.cornerRadius = 6.0
        backgroundColor = Constants.defaultBackgroundColor
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect.inset(by: insets))
    }

}
