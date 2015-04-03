import Foundation


public class NoteSeparatorsView : UIView
{
    // MARK: - Public Properties
    public var leftSeparatorVisible : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public var leftSeparatorColor : UIColor = UIColor.clearColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    public var leftSeparatorWidth : CGFloat = CGFloat(3) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomSeparatorVisible : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomSeparatorColor : UIColor = UIColor.clearColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomSeparatorHeight : CGFloat = CGFloat(0.5) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var bottomSeparatorInsets : UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            setNeedsDisplay()
        }
    }

    
    // MARK: - UIView methods
    public override init() {
        super.init()
        setupView()
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    public override func drawRect(rect: CGRect) {
        
        super.drawRect(rect)
        
        let scale = UIScreen.mainScreen().scale
        let ctx = UIGraphicsGetCurrentContext()
        CGContextClearRect(ctx, rect);

        // Left Separator
        if leftSeparatorVisible {
            leftSeparatorColor.setStroke()
            CGContextSetLineWidth(ctx, leftSeparatorWidth * scale);
            CGContextMoveToPoint(ctx, bounds.minX, bounds.minY)
            CGContextAddLineToPoint(ctx, bounds.minX, bounds.maxY)
            CGContextStrokePath(ctx);
        }
        
        // Bottom Separator
        if bottomSeparatorVisible {
            bottomSeparatorColor.setStroke()
            CGContextSetLineWidth(ctx, bottomSeparatorHeight * scale);
            CGContextMoveToPoint(ctx, bottomSeparatorInsets.left, bounds.height)
            CGContextAddLineToPoint(ctx, bounds.width - bottomSeparatorInsets.left - bottomSeparatorInsets.right, bounds.height)
            CGContextStrokePath(ctx);
        }
    }
    
    private func setupView() {
        backgroundColor = UIColor.clearColor()
    }
}
