import Foundation


//  NOTE:
//  ReplyBezierView is a helper class, used to render the ReplyTextView bubble
//
public class ReplyBezierView : UIView
{
    
    public var fieldBackgroundColor: UIColor = WPStyleGuide.Reply.backgroundColor {
        didSet {
            setNeedsDisplay()
        }
    }
    public var separatorColor: UIColor = WPStyleGuide.Reply.separatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topLineHeight: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }
    public var cornerRadius: CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    public var insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 54) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Initializers
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        // Make sure this is re-drawn on rotation events
        layer.needsDisplayOnBoundsChange    = true
    }
    
    // MARK: - View Methods
    public override func drawRect(rect: CGRect) {
        // Draw the background, while clipping a rounded rect with the given insets
        var bezierRect                      = bounds
        bezierRect.origin.x                 += insets.left
        bezierRect.origin.y                 += insets.top
        bezierRect.size.height              -= insets.top + insets.bottom
        bezierRect.size.width               -= insets.left + insets.right
        let bezier                          = UIBezierPath(roundedRect: bezierRect, cornerRadius: cornerRadius)
        let outer                           = UIBezierPath(rect: bounds)
        
        separatorColor.set()
        bezier.stroke()
        
        fieldBackgroundColor.set()
        bezier.appendPath(outer)
        bezier.usesEvenOddFillRule = true
        bezier.fill()
        
        // Draw the top separator line
        separatorColor.set()
        
        let topHeightInPixels = topLineHeight / UIScreen.mainScreen().scale
        let topLineFrame = CGRect(x: 0, y: 0, width: bounds.width, height: topHeightInPixels)
        UIRectFill(topLineFrame)
    }
}

