import UIKit
import WordPressShared

open class WPHelpIndicatorView: UIView {

    struct Constants {
        static let defaultInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let defaultBackgroundColor = WPStyleGuide.jazzyOrange()
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
        super.draw(UIEdgeInsetsInsetRect(rect, insets))
    }

}
