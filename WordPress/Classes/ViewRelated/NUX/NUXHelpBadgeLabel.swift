import UIKit
import WordPressShared


// MARK: - NUXHelpBadgeLabel
//
class NUXHelpBadgeLabel: UILabel {

    struct Constants {
        static let defaultInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let defaultBackgroundColor = UIColor(fromHex: 0xdd3d36)
        static let defaultFont = WPFontManager.systemRegularFont(ofSize: 8.0)
    }

    var insets: UIEdgeInsets = Constants.defaultInsets {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    func commonSetup() {
        layer.masksToBounds = true
        layer.cornerRadius = 6.0
        textAlignment = .center
        backgroundColor = Constants.defaultBackgroundColor
        textColor = .white
        font = Constants.defaultFont
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
