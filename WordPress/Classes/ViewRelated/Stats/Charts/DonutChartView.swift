import UIKit

class DonutChartView: UIView {

    // MARK: Views

    private var segmentLayers = [CAShapeLayer]()

    private var titleStackView: UIStackView!
    private var titleLabel: UILabel!
    private var totalCountLabel: UILabel!
    private var chartContainer: UIView!
    private var legendStackView: UIStackView!

    // MARK: Configuration

    struct Segment {
        let title: String
        let value: Float
        let color: UIColor
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var totalCount: Float = 0 {
        didSet {
            totalCountLabel.text = String(Int(totalCount))
        }
    }

    var segments: [Segment] = []

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .basicBackground

        configureChartContainer()
        configureTitleViews()
        configureLegend()
        configureConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureChartContainer() {
        chartContainer = UIView()
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartContainer)
    }

    private func configureTitleViews() {
        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)

        totalCountLabel = UILabel()
        totalCountLabel.textAlignment = .center
        totalCountLabel.font = .preferredFont(forTextStyle: .title1).bold()

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, totalCountLabel])

        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .vertical
        titleStackView.spacing = Constants.titleStackViewSpacing

        addSubview(titleStackView)
    }

    private func configureLegend() {
        legendStackView = UIStackView()
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.spacing = Constants.legendStackViewSpacing
        legendStackView.distribution = .equalSpacing

        addSubview(legendStackView)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            chartContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartContainer.topAnchor.constraint(equalTo: topAnchor),

            legendStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            legendStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            legendStackView.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: Constants.chartToLegendSpacing),
            legendStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.innerTextPadding),
            titleStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.innerTextPadding),
            titleStackView.centerYAnchor.constraint(equalTo: chartContainer.centerYAnchor),
            titleStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Constants.innerTextPadding),
            titleStackView.bottomAnchor.constraint(lessThanOrEqualTo: chartContainer.bottomAnchor, constant: -Constants.innerTextPadding)
        ])
    }

    /// Initializes the chart display with the provided data.
    ///
    /// - Parameters:
    ///     - title: Displayed in the center of the chart
    ///     - totalCount: Displayed in the center of the chart and used to calculate segment sizes
    ///     - segments: Used for color, legend titles, and segment size
    func configure(title: String?, totalCount: Float, segments: [Segment]) {
        if segments.reduce(0.0, { $0 + $1.value }) > totalCount {
            // DDLogInfo
            print("DonutChartView: Segment values should total less than 100%.")
        }

        self.title = title
        self.totalCount = totalCount
        self.segments = segments

        segments.forEach({ legendStackView.addArrangedSubview(LegendView(segment: $0)) })

        layoutChart()
    }

    private func layoutChart() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Clear out any existing segments
        segmentLayers.forEach({ $0.removeFromSuperlayer() })
        segmentLayers = []

        guard totalCount > 0 else {
            // We must have a total count greater than 0, as we use it to calculate percentages
            print("DonutChartView: TotalCount must be greater than 0 for chart initialization.")
            return
        }

        var currentTotal: Float = 0.0

        for segment in segments {
            let segmentLayer = makeSegmentLayer()
            segmentLayer.strokeColor = segment.color.cgColor

            // Calculate the start and end of the new segment
            let segmentStartPercentage = CGFloat(currentTotal / totalCount)
            currentTotal += segment.value
            let segmentEndPercentage = CGFloat(currentTotal / totalCount)

            let path = UIBezierPath(arcCenter: chartCenterPoint,
                                    radius: chartRadius,
                                    startAngle: radiansFromPercent(segmentStartPercentage) + segmentOffset,
                                    endAngle: radiansFromPercent(segmentEndPercentage) - segmentOffset,
                                    clockwise: true)
            segmentLayer.path = path.cgPath

            segmentLayers.append(segmentLayer)
        }

        segmentLayers.forEach({ chartContainer.layer.addSublayer($0) })

        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !segmentLayers.isEmpty {
            layoutChart()
        }
    }

    // MARK: Helpers

    private func makeSegmentLayer() -> CAShapeLayer {
        let segmentLayer = CAShapeLayer()
        segmentLayer.frame = chartContainer.bounds
        segmentLayer.lineWidth = Constants.lineWidth
        segmentLayer.fillColor = UIColor.clear.cgColor
        segmentLayer.lineCap = .round

        return segmentLayer
    }

    private var chartCenterPoint: CGPoint {
        return CGPoint(x: chartContainer.bounds.midX, y: chartContainer.bounds.midY)
    }

    private var chartRadius: CGFloat {
        let smallestDimension = min(chartContainer.bounds.width, chartContainer.bounds.height)
        return (smallestDimension / 2.0) - (Constants.lineWidth / 2.0)
    }

    /// Offset used to adjust the endpoints of each chart segment so that the end caps
    /// don't overlap, as they draw from their center not from the line edge
    private var segmentOffset: CGFloat {
        return asin(Constants.lineWidth * 0.5 / chartRadius)
    }

    private func radiansFromPercent(_ percent: CGFloat) -> CGFloat {
        return (percent * 2.0 * CGFloat.pi) - (CGFloat.pi / 2.0)
    }

    // MARK: Constants

    enum Constants {
        static let lineWidth: CGFloat = 16.0
        static let innerTextPadding: CGFloat = 24.0
        static let titleStackViewSpacing: CGFloat = 8.0
        static let legendStackViewSpacing: CGFloat = 8.0
        static let chartToLegendSpacing: CGFloat = 32.0
    }
}

// MARK: - Legend View

private class LegendView: UIView {
    let segment: DonutChartView.Segment

    init(segment: DonutChartView.Segment) {
        self.segment = segment

        super.init(frame: .zero)

        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        let indicator = UIView()
        indicator.backgroundColor = segment.color
        indicator.layer.cornerRadius = 6.0

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.text = segment.title

        let stackView = UIStackView(arrangedSubviews: [indicator, titleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8.0
        addSubview(stackView)

        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 12.0),
            indicator.heightAnchor.constraint(equalToConstant: 12.0),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
