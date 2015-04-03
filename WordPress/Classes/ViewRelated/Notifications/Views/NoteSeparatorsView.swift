import Foundation


public class NoteSeparatorsView : UIView
{
    // MARK: - Public Properties
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
    public var bottomSeparatorHeight : CGFloat = CGFloat(1) {
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
        
        let ctx = UIGraphicsGetCurrentContext()
        CGContextClearRect(ctx, rect);
        
        // Bottom Separator
        if bottomSeparatorVisible == false {
            return
        }
        
        bottomSeparatorColor.setStroke()
        CGContextSetLineWidth(ctx, bottomSeparatorHeight);
        CGContextMoveToPoint(ctx, bottomSeparatorInsets.left, bounds.height)
        CGContextAddLineToPoint(ctx, bounds.width - bottomSeparatorInsets.left - bottomSeparatorInsets.right, bounds.height)
        CGContextStrokePath(ctx);
    }
    
    private func setupView() {
        backgroundColor = UIColor.clearColor()
    }
}
