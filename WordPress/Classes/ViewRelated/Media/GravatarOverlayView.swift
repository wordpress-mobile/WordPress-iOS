import Foundation
import UIKit


// Renders an "Outer Ellipse Overlay", to be used on top of the Gravatar Image
//
class GravatarOverlayView: UIView {
    // MARK: - Public Properties
    var borderWidth = CGFloat(3)
    var borderColor: UIColor?
    var outerColor: UIColor?

    // MARK: - Overriden Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let context = UIGraphicsGetCurrentContext()!

        // Prevent Ellipse Clipping
        let delta = borderWidth - 1.0
        let ellipseRect = bounds.insetBy(dx: delta, dy: delta)

        // Setup
        context.saveGState()
        context.setLineWidth(borderWidth)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        // Outer
        outerColor?.setFill()
        context.addRect(bounds)
        context.addEllipse(in: ellipseRect)
        context.fillPath(using: .evenOdd)

        // Border
        borderColor?.setStroke()
        context.addEllipse(in: ellipseRect)
        context.strokePath()

        // Wrap Up
        context.restoreGState()
    }
}
