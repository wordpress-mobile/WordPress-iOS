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

    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)

        updateAppearance()
    }

    private func updateAppearance() {
        contentEdgeInsets = UIEdgeInsets(top: verticalEdgeInset, left: horizontalEdgeInset, bottom: verticalEdgeInset, right: horizontalEdgeInset)

        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.CGColor

        setTitleColor(tintColor, forState: .Normal)

        if reversesTitleShadowWhenHighlighted {
            setTitleColor(backgroundColor, forState: [.Highlighted])
            setBackgroundImage(UIImage(color: tintColor), forState: .Highlighted)
        } else {
            setTitleColor(tintColor.colorWithAlphaComponent(0.3), forState: .Highlighted)
        }
    }
}
