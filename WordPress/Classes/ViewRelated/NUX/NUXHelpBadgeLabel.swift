import UIKit
import WordPressShared

class NUXHelpBadgeLabel: UILabel {
    private let insets = UIEdgeInsets(top: 0, left: 0, bottom: 1, right: 0)

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
        backgroundColor = UIColor(fromHex: 0xdd3d36)
        textColor = .white
        font = WPFontManager.systemRegularFont(ofSize: 8.0)
    }

    override func draw(_ rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
