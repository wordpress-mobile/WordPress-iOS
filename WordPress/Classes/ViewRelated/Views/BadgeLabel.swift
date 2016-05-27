import UIKit

class BadgeLabel: UILabel {
    @IBInspectable var horizontalPadding: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

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
        textAlignment = .Center
        layer.masksToBounds = true

        cornerRadius = 2.0
    }

    // MARK: Padding

    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsetsMake(0, horizontalPadding, 0, horizontalPadding)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }

    override func intrinsicContentSize() -> CGSize {
        var paddedSize = super.intrinsicContentSize()
        paddedSize.width += 2 * horizontalPadding
        return paddedSize
    }

    //  MARK: Computed Properties

    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(CGColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.CGColor
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}
