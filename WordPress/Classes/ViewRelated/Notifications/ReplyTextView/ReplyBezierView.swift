import Foundation
import WordPressShared.WPStyleGuide

//  NOTE:
//  ReplyBezierView is a helper class, used to render the ReplyTextView bubble
//
class ReplyBezierView: UIView {
    @objc var outerColor = WPStyleGuide.Reply.backgroundColor {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc var bezierColor = WPStyleGuide.Reply.separatorColor {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc var bezierFillColor: UIColor? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc var bezierRadius = CGFloat(5) {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc var insets = UIEdgeInsets(top: 8, left: 1, bottom: 8, right: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Initializers
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    fileprivate func setupView() {
        // Make sure this is re-drawn on rotation events
        layer.needsDisplayOnBoundsChange = true
    }

    // MARK: - View Methods
    override func draw(_ rect: CGRect) {
        // Draw the background, while clipping a rounded rect with the given insets
        var bezierRect          = bounds
        bezierRect.origin.x     += insets.left
        bezierRect.origin.y     += insets.top
        bezierRect.size.height  -= insets.top + insets.bottom
        bezierRect.size.width   -= insets.left + insets.right
        let bezier              = UIBezierPath(roundedRect: bezierRect, cornerRadius: bezierRadius)
        let outer               = UIBezierPath(rect: bounds)

        if let fillColor = bezierFillColor {
            fillColor.set()
            bezier.fill()
        }

        bezierColor.set()
        bezier.stroke()

        outerColor.set()
        bezier.append(outer)
        bezier.usesEvenOddFillRule = true
        bezier.fill()
    }
}
