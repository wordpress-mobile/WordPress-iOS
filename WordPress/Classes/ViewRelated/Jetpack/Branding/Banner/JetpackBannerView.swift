import UIKit

class JetpackBannerView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override var intrinsicContentSize: CGSize {
        return isHidden ? CGSize.zero : super.intrinsicContentSize
    }

    func setup() {
        backgroundColor = Self.jetpackBannerBackgroundColor

        let jetpackButton = JetpackButton(style: .banner)
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(jetpackButton)

        pinSubviewToAllEdges(jetpackButton)
    }

    private static let jetpackBannerBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                              dark: .muriel(color: .jetpackGreen, .shade90))
}
