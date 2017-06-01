import Foundation
import UIKit


// Renders an "Outer Ellipse or Square Overlay", to be used on top of the Image
// Defaults to an Ellipse
//
class ImageCropOverlayView: UIView {
    // MARK: - Public Properties
    var borderWidth = CGFloat(3)
    var borderColor: UIColor?
    var outerColor: UIColor?
    var square: Bool = false

    // MARK: - Overriden Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let context = UIGraphicsGetCurrentContext()!

        // Setup
        context.saveGState()
        context.setLineWidth(borderWidth)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        // Outer
        outerColor?.setFill()
        context.addRect(bounds)
        // Prevent from clipping
        let delta = borderWidth - 1.0
        if square {
            let squareRect = bounds.insetBy(dx: delta, dy: delta)
            context.addRect(squareRect)
            context.fillPath(using: .evenOdd)
            context.addRect(squareRect)
        } else {
            let ellipseRect = bounds.insetBy(dx: delta, dy: delta)
            context.addEllipse(in: ellipseRect)
            context.fillPath(using: .evenOdd)
            context.addEllipse(in: ellipseRect)
        }
        // Border
        borderColor?.setStroke()
        context.strokePath()
        // Wrap Up
        context.restoreGState()
    }
}
