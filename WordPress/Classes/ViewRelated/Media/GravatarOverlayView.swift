import Foundation
import UIKit


// Renders an "Outer Ellipse Overlay", to be used on top of the Gravatar Image
//
class GravatarOverlayView : UIView
{
    // MARK: - Public Properties
    var borderWidth = CGFloat(3)
    var borderColor : UIColor?
    var outerColor : UIColor?

    // MARK: - Overriden Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let context = UIGraphicsGetCurrentContext()

        // Prevent Ellipse Clipping
        let delta = borderWidth - 1.0
        let ellipseRect = bounds.insetBy(dx: delta, dy: delta)

        // Setup
        CGContextSaveGState(context)
        CGContextSetLineWidth(context, borderWidth)
        CGContextSetAllowsAntialiasing(context, true)
        CGContextSetShouldAntialias(context, true)

        // Outer
        outerColor?.setFill()
        CGContextAddRect(context, bounds)
        CGContextAddEllipseInRect(context, ellipseRect)
        CGContextEOFillPath(context)

        // Border
        borderColor?.setStroke()
        CGContextAddEllipseInRect(context, ellipseRect)
        CGContextStrokePath(context)

        // Wrap Up
        CGContextRestoreGState(context)
    }
}
