import UIKit
import WordPressShared

class LoginTextField: WPWalkthroughTextField {

    override func draw(_ rect: CGRect) {
        if showTopLineSeparator {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }

            drawTopLine(rect: rect, context: context)
            drawBottomLine(rect: rect, context: context)
        }
    }

    private func drawTopLine(rect: CGRect, context: CGContext) {
        drawBorderLine(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY), context: context)
    }

    private func drawBottomLine(rect: CGRect, context: CGContext) {
        drawBorderLine(from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.maxX, y: rect.maxY), context: context)
    }

    private func drawBorderLine(from startPoint: CGPoint, to endPoint: CGPoint, context: CGContext) {
        let path = UIBezierPath()

        path.move(to: startPoint)
        path.addLine(to: endPoint)
        path.lineWidth = UIScreen.main.scale / 2.0
        context.addPath(path.cgPath)
        context.setStrokeColor(WPStyleGuide.greyLighten20().cgColor)
        context.strokePath()
    }
}
