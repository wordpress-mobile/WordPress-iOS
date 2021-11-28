import UIKit

class BadgeLabel: UILabel {
    @IBInspectable var horizontalPadding: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    @IBInspectable var verticalPadding: CGFloat = 0 {
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

    fileprivate func setupView() {
        textAlignment = .center
        layer.masksToBounds = true

        cornerRadius = 2.0
    }

    // MARK: Padding

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        var paddedSize = super.intrinsicContentSize
        paddedSize.width += 2 * horizontalPadding
        paddedSize.height += 2 * verticalPadding
        return paddedSize
    }

    // MARK: Computed Properties

    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.cgColor
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
