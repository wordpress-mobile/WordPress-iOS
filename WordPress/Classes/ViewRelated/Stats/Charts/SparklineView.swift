import UIKit
import simd

class SparklineView: UIView {
    private let lineLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()

    private static let defaultChartColor = UIColor.muriel(name: .blue, .shade50)
    var chartColor: UIColor! = SparklineView.defaultChartColor {
        didSet {
            if chartColor == nil {
                chartColor = SparklineView.defaultChartColor
            }
        }
    }

    var data: [CGFloat] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        let initialData = [102, 109, 526, 253, 163, 227, 101].map({ CGFloat($0) })
        data = interpolateData(initialData)

        initializeChart()
        layoutChart()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutChart()
    }

    func initializeChart() {layer.isGeometryFlipped = true

        lineLayer.strokeColor = chartColor.cgColor
        lineLayer.lineWidth = Constants.lineWidth
        lineLayer.fillColor = UIColor.clear.cgColor

        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.fillColor = UIColor.black.cgColor

        gradientLayer.startPoint = Constants.gradientStart
        gradientLayer.endPoint = Constants.gradientEnd
        gradientLayer.colors = [chartColor.cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor]
        gradientLayer.mask = maskLayer
        gradientLayer.opacity = Constants.gradientOpacity

        layer.addSublayer(gradientLayer)
        layer.addSublayer(lineLayer)
    }

    private func interpolateData(_ inputData: [CGFloat]) -> [CGFloat] {
        guard inputData.count > 0,
              let first = inputData.first else {
            return []
        }

        var interpolatedData = [first]

        for (this, next) in zip(inputData, inputData.dropFirst()) {
            let interpolationIncrement = (next - this) / Constants.interpolationCount

            for index in stride(from: 1, through: Constants.interpolationCount, by: 1) {
                let normalized = simd_smoothstep(this, next, this + (index * interpolationIncrement))
                let actual = simd_mix(this, next, normalized)

                interpolatedData.append(actual)
            }
        }

        return interpolatedData
    }

    private func layoutChart() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        lineLayer.frame = bounds
        maskLayer.frame = bounds
        gradientLayer.frame = bounds

        // Calculate points to fit along X axis, using existing interpolated Y values
        let segmentWidth = bounds.width / CGFloat(data.count-1)
        let points = data.enumerated().map({ CGPoint(x: CGFloat($0.offset) * segmentWidth, y: $0.element) })

        // Scale Y values to fit within our bounds
        let maxYValue = points.map(\.y).max() ?? 1.0
        let scaleFactor = bounds.height / maxYValue
        let scaleTransform = CGAffineTransform(scaleX: 1.0, y: scaleFactor)

        // Scale the points slightly so that the line remains within bounds, based on the line width.
        let xScaleFactor = (bounds.width - Constants.lineWidth) / bounds.width
        let yScaleFactor = (bounds.height - Constants.lineWidth) / bounds.height

        let halfLineWidth = Constants.lineWidth / 2.0
        var lineTransform = CGAffineTransform(translationX: halfLineWidth, y: halfLineWidth)
        lineTransform = lineTransform.scaledBy(x: xScaleFactor, y: yScaleFactor)
        lineTransform = lineTransform.concatenating(scaleTransform)

        // Finally, create the paths – first the line...
        let lineLayerPath = CGMutablePath()
        lineLayerPath.addLines(between: points, transform: lineTransform)

        lineLayer.path = lineLayerPath

        // ... then the bottom gradient
        if let maskLayerPath = lineLayerPath.mutableCopy() {
            maskLayerPath.addLine(to: CGPoint(x: bounds.width, y: 0))
            maskLayerPath.addLine(to: CGPoint(x: 0, y: 0))
            maskLayer.path = maskLayerPath
        }

        CATransaction.commit()
    }

    private enum Constants {
        static let lineWidth: CGFloat = 2.0
        static let gradientOpacity: Float = 0.1

        // This number of extra data points will be interpolated in between each pair of original data points.
        // The higher the number, the smoother the chart line.
        static let interpolationCount: Double = 20

        static let gradientStart = CGPoint(x: 0.0, y: 0.5)
        static let gradientEnd = CGPoint(x: 1.0, y: 0.5)
    }
}
