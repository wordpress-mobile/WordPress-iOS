import Foundation
import WordPressShared

public class SeparatorsView : UIView
{
    // MARK: - Public Properties
    public var leftVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public var leftColor = UIColor.clearColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    public var leftWidthInPoints = CGFloat(3) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topColor = WPStyleGuide.Notifications.blockSeparatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topInsets = UIEdgeInsetsZero {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomColor = WPStyleGuide.Notifications.blockSeparatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomInsets = UIEdgeInsetsZero {
        didSet {
            setNeedsDisplay()
        }
    }
    public override var frame : CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    
    // MARK: - UIView methods
    convenience init() {
        self.init(frame: CGRectZero)
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let scale = UIScreen.mainScreen().scale
        let ctx = UIGraphicsGetCurrentContext()
        CGContextClearRect(ctx, rect);
        CGContextSetShouldAntialias(ctx, false);

        // Background
        if backgroundColor != nil {
            backgroundColor?.setFill()
            CGContextFillRect(ctx, rect)
        }
        
        // Left Separator
        if leftVisible {
            leftColor.setStroke()
            CGContextSetLineWidth(ctx, leftWidthInPoints * scale);
            CGContextMoveToPoint(ctx, bounds.minX, bounds.minY)
            CGContextAddLineToPoint(ctx, bounds.minX, bounds.maxY)
            CGContextStrokePath(ctx);
        }

        // Top Separator
        if topVisible {
            topColor.setStroke()
            let lineWidth = topHeightInPixels / scale
            CGContextSetLineWidth(ctx, lineWidth);
            CGContextMoveToPoint(ctx, topInsets.left, lineWidth)
            CGContextAddLineToPoint(ctx, bounds.maxX - topInsets.right, lineWidth)
            CGContextStrokePath(ctx);
        }

        // Bottom Separator
        if bottomVisible {
            bottomColor.setStroke()
            CGContextSetLineWidth(ctx, bottomHeightInPixels / scale);
            CGContextMoveToPoint(ctx, bottomInsets.left, bounds.height)
            CGContextAddLineToPoint(ctx, bounds.maxX - bottomInsets.right, bounds.height)
            CGContextStrokePath(ctx);
        }
    }
    
    private func setupView() {
        backgroundColor = UIColor.clearColor()
        
        // Make sure this is re-drawn if the bounds change!
        layer.needsDisplayOnBoundsChange = true
    }
}
