import Foundation
import WordPressShared

open class SeparatorsView: UIView {
    // MARK: - Public Properties
    @objc open var leftVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var leftColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var leftWidthInPoints = CGFloat(3) {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var topVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var topColor = WPStyleGuide.Notifications.blockSeparatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var topHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var topInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var bottomVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var bottomColor = WPStyleGuide.Notifications.blockSeparatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var bottomHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }
    @objc open var bottomInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsDisplay()
        }
    }
    open override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }



    // MARK: - UIView methods
    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        let scale = UIScreen.main.scale
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.clear(rect)
        ctx!.setShouldAntialias(false)

        // Background
        if backgroundColor != nil {
            backgroundColor?.setFill()
            ctx!.fill(rect)
        }

        // Left Separator
        if leftVisible {
            leftColor.setStroke()
            ctx!.setLineWidth(leftWidthInPoints * scale)
            ctx!.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            ctx!.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            ctx!.strokePath()
        }

        // Top Separator
        if topVisible {
            topColor.setStroke()
            let lineWidth = topHeightInPixels / scale
            ctx!.setLineWidth(lineWidth)
            ctx!.move(to: CGPoint(x: topInsets.left, y: lineWidth))
            ctx!.addLine(to: CGPoint(x: bounds.maxX - topInsets.right, y: lineWidth))
            ctx!.strokePath()
        }

        // Bottom Separator
        if bottomVisible {
            bottomColor.setStroke()
            ctx!.setLineWidth(bottomHeightInPixels / scale)
            ctx!.move(to: CGPoint(x: bottomInsets.left, y: bounds.height))
            ctx!.addLine(to: CGPoint(x: bounds.maxX - bottomInsets.right, y: bounds.height))
            ctx!.strokePath()
        }
    }

    fileprivate func setupView() {
        backgroundColor = UIColor.clear

        // Make sure this is re-drawn if the bounds change!
        layer.needsDisplayOnBoundsChange = true
    }
}
