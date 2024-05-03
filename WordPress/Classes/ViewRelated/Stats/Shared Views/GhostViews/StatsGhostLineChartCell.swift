import UIKit
import WordPressShared

class StatsGhostLineChartCell: StatsGhostBaseCell, NibLoadable {
    @IBOutlet private weak var lineChart: StatsGhostLineChartView!
}

final class StatsGhostLineChartView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        createMask()
    }

    private func createMask() {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.maxY))

        let wavePoints = [
            CGPoint(x: bounds.width * 0.1, y: bounds.maxY * 0.8),
            CGPoint(x: bounds.width * 0.3, y: bounds.maxY * 0.6),
            CGPoint(x: bounds.width * 0.5, y: bounds.maxY * 0.4),
            CGPoint(x: bounds.width * 0.7, y: bounds.maxY * 0.2),
            CGPoint(x: bounds.width * 0.9, y: bounds.maxY * 0.5),
            CGPoint(x: bounds.width, y: 0)
        ]

        for (index, point) in wavePoints.enumerated() {
            if index == 0 {
                path.addLine(to: point)
            } else {
                let previousPoint = wavePoints[index - 1]
                let midPointX = (previousPoint.x + point.x) / 2
                path.addCurve(to: point, controlPoint1: CGPoint(x: midPointX, y: previousPoint.y), controlPoint2: CGPoint(x: midPointX, y: point.y))
            }
        }

        path.addLine(to: CGPoint(x: bounds.width, y: 0))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.maxY))
        path.close()

        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.fillRule = .evenOdd
        layer.mask = maskLayer
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.frame = bounds }
        createMask()
    }
}
