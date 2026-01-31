import SwiftUI
import Charts

/// Simplified bar chart for metrics without tooltips or comparison bars.
struct SimpleBarChartView: View {
    let data: SimpleChartData
    let selectedDate: Date?
    let onBarTapped: (Date) -> Void

    @State private var hoveredDate: Date?
    @State private var isInteracting = false

    @Environment(\.context) var context
    @Environment(\.colorScheme) private var colorScheme

    private var valueFormatter: any ValueFormatterProtocol {
        data.metric.makeValueFormatter()
    }

    private var currentAverage: Double {
        guard !data.currentData.isEmpty else { return 0 }
        return Double(data.currentTotal) / Double(data.currentData.count)
    }

    var body: some View {
        Chart {
            currentPeriodBars
            averageLine
            peakAnnotation
            selectionIndicator
        }
        .chartXAxis { xAxis }
        .chartYAxis { yAxis }
        .chartYScale(domain: yAxisDomain)
        .chartLegend(.hidden)
        .animation(.spring, value: ObjectIdentifier(data))
        .chartOverlay { proxy in
            makeOverlayView(proxy: proxy)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: - Chart Marks

    @ChartContentBuilder
    private var currentPeriodBars: some ChartContent {
        ForEach(data.currentData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component),
                y: .value("Value", point.value),
                width: barWidth
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        data.metric.primaryColor,
                        lighten(data.metric.primaryColor)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
            .opacity(getBarOpacity(for: point))
        }
    }

    private var barWidth: MarkDimension {
        data.currentData.count <= 3 ? .fixed(32) : .automatic
    }

    private func lighten(_ color: Color) -> Color {
        if #available(iOS 18, *) {
            color.mix(with: Color(.systemBackground), by: colorScheme == .light ? 0.4 : 0.15)
        } else {
            color.opacity(0.5)
        }
    }

    private func getBarOpacity(for point: DataPoint) -> CGFloat {
        let dateToMatch = isInteracting ? hoveredDate : selectedDate
        guard let dateToMatch else { return 1.0 }

        return context.calendar.isDate(
            point.date,
            equalTo: dateToMatch,
            toGranularity: data.granularity.component
        ) ? 1.0 : 0.5
    }

    @ChartContentBuilder
    private var averageLine: some ChartContent {
        if currentAverage > 0 {
            RuleMark(y: .value("Average", currentAverage))
                .foregroundStyle(Color.secondary.opacity(0.33))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .annotation(position: .trailing, alignment: .trailing) {
                    ChartAverageAnnotation(value: Int(currentAverage), formatter: valueFormatter)
                }
        }
    }

    @ChartContentBuilder
    private var peakAnnotation: some ChartContent {
        if let maxPoint = data.currentData.max(by: { $0.value < $1.value }), data.currentData.count > 0 {
            PointMark(
                x: .value("Date", maxPoint.date, unit: data.granularity.component),
                y: .value("Value", maxPoint.value)
            )
            .opacity(0)
            .annotation(position: .top, spacing: 8) {
                PeakValueAnnotation(value: maxPoint.value, metric: data.metric)
                    // Hide when interacting to avoid clutter
                    .opacity(isInteracting ? 0 : 1)
            }
        }
    }

    @ChartContentBuilder
    private var selectionIndicator: some ChartContent {
        let dateToMatch = isInteracting ? hoveredDate : selectedDate
        if let dateToMatch,
           let selectedPoint = data.currentData.first(where: { point in
               context.calendar.isDate(
                   point.date,
                   equalTo: dateToMatch,
                   toGranularity: data.granularity.component
               )
           }) {
            // Subtle vertical background fill for entire bar area
            RectangleMark(
                x: .value("Date", selectedPoint.date, unit: data.granularity.component),
                yStart: .value("Bottom", 0),
                yEnd: .value("Top", yAxisDomain.upperBound),
                width: barWidth
            )
            .foregroundStyle(data.metric.primaryColor.opacity(colorScheme == .light ? 0.08 : 0.12))
            .zIndex(-1)
        }
    }

    // MARK: - Axis Configuration

    private var xAxis: some AxisContent {
        if data.currentData.count == 1 {
            AxisMarks(values: .stride(by: data.granularity.component, count: 1)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        ChartAxisDateLabel(date: date, granularity: data.granularity)
                    }
                }
            }
        } else {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        ChartAxisDateLabel(date: date, granularity: data.granularity)
                    }
                }
            }
        }
    }

    private var yAxis: some AxisContent {
        AxisMarks(values: .automatic) { value in
            if let value = value.as(Int.self) {
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.33))
                AxisValueLabel {
                    if value > 0 {
                        Text(valueFormatter.format(value: value, context: .compact))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var yAxisDomain: ClosedRange<Int> {
        // If all values are zero, show a reasonable range
        if data.maxValue == 0 {
            return 0...100
        }
        guard data.maxValue > 0 else {
            return data.maxValue...0
        }
        // Add some padding above the max value
        let padding = max(Int(Double(data.maxValue) * 0.33), 1)
        return 0...(data.maxValue + padding)
    }

    // MARK: - Gesture Handling

    private func makeOverlayView(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            ChartGestureOverlay(
                onTap: { location in
                    handleTap(at: location, proxy: proxy, geometry: geometry)
                },
                onInteractionUpdate: { location in
                    isInteracting = true
                    if let date = getDate(at: location, proxy: proxy, geometry: geometry) {
                        hoveredDate = date
                        onBarTapped(date)
                    }
                },
                onInteractionEnd: {
                    isInteracting = false
                    hoveredDate = nil
                }
            )
        }
    }

    private func handleTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard !isInteracting,
              let date = getDate(at: location, proxy: proxy, geometry: geometry) else {
            return
        }
        onBarTapped(date)
    }

    private func getDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Date? {
        guard let frame = proxy.plotFrame else { return nil }

        let origin = geometry[frame].origin
        let adjustedX = location.x - origin.x

        return proxy.value(atX: adjustedX)
    }
}

// MARK: - Supporting Views

private struct PeakValueAnnotation: View {
    let value: Int
    let metric: any MetricType
    let valueFormatter: any ValueFormatterProtocol

    @Environment(\.colorScheme) private var colorScheme

    init(value: Int, metric: any MetricType) {
        self.value = value
        self.metric = metric
        self.valueFormatter = metric.makeValueFormatter()
    }

    var body: some View {
        Text(valueFormatter.format(value: value, context: .compact))
            .fixedSize()
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundColor(metric.primaryColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                ZStack {
                    Capsule()
                        .fill(Color(.systemBackground).opacity(0.75))
                    Capsule()
                        .fill(metric.primaryColor.opacity(colorScheme == .light ? 0.1 : 0.25))
                }
            }
    }
}

// MARK: - Preview

#Preview("Days") {
    SimpleBarChartView(
        data: SimpleChartData.mock(metric: WordAdsMetric.impressions, granularity: .day, dataPointCount: 7),
        selectedDate: nil,
        onBarTapped: { _ in }
    )
    .frame(height: 180)
    .padding()
    .background(Constants.Colors.background)
}

#Preview("With Selection") {
    SimpleBarChartView(
        data: SimpleChartData.mock(metric: WordAdsMetric.revenue, granularity: .day, dataPointCount: 7),
        selectedDate: Date(),
        onBarTapped: { _ in }
    )
    .frame(height: 180)
    .padding()
    .background(Constants.Colors.background)
}

#Preview("Months") {
    SimpleBarChartView(
        data: SimpleChartData.mock(metric: WordAdsMetric.cpm, granularity: .month, dataPointCount: 12),
        selectedDate: nil,
        onBarTapped: { _ in }
    )
    .frame(height: 180)
    .padding()
    .background(Constants.Colors.background)
}
