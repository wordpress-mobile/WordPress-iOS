import UIKit
import WordPressShared
import DesignSystem

final class StatsGhostLineChartCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let lineChart = StatsGhostLineChartView()
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lineChart)
        topConstraint = lineChart.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        topConstraint?.isActive = true
        NSLayoutConstraint.activate([
            lineChart.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .DS.Padding.double),
            contentView.trailingAnchor.constraint(equalTo: lineChart.trailingAnchor, constant: .DS.Padding.double),
            contentView.bottomAnchor.constraint(equalTo: lineChart.bottomAnchor, constant: .DS.Padding.single),
            lineChart.heightAnchor.constraint(equalToConstant: 190),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
