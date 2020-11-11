import UIKit

class LinearGradientView: UIView {
    @IBInspectable var startColor: UIColor? = nil
    @IBInspectable var endColor: UIColor? = nil

    @IBInspectable var startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0)
    @IBInspectable var endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        contentMode = .redraw
    }

    private func configure() {
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard
            let context = UIGraphicsGetCurrentContext(),
            let startColor = startColor?.cgColor,
            let endColor = endColor?.cgColor
        else {
            return
        }

        context.saveGState()

        defer { context.restoreGState() }

        let path = UIBezierPath(rect: bounds)
        path.addClip()

        let width = bounds.width
        let height = bounds.height

        let start = CGPoint(x: startPoint.x * width, y: startPoint.y * height)
        let end = CGPoint(x: endPoint.x * width, y: endPoint.y * height)

        let colors = [startColor, endColor] as CFArray
        guard
            let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)
        else {
            return
        }

        context.drawLinearGradient(gradient,
                                   start: start,
                                   end: end,
                                   options: [])
    }
}
