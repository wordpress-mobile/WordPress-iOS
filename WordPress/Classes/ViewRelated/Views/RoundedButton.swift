import UIKit

@IBDesignable
class RoundedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var horizontalEdgeInset: CGFloat = 19.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var verticalEdgeInset: CGFloat = 10.0 {
        didSet {
            updateAppearance()
        }
    }

    override var reversesTitleShadowWhenHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        updateAppearance()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        updateAppearance()
    }

    fileprivate func updateAppearance() {
        contentEdgeInsets = UIEdgeInsets(top: verticalEdgeInset, left: horizontalEdgeInset, bottom: verticalEdgeInset, right: horizontalEdgeInset)

        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.cgColor

        setTitleColor(tintColor, for: UIControlState())

        if reversesTitleShadowWhenHighlighted {
            setTitleColor(backgroundColor, for: [.highlighted])
            setBackgroundImage(UIImage(color: tintColor), for: .highlighted)
        } else {
            setTitleColor(tintColor.withAlphaComponent(0.3), for: .highlighted)
        }
    }
}
