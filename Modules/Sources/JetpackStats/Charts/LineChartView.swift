import SwiftUI
import Charts

struct LineChartView: View {
    let data: ChartData

    @State private var selectedDate: Date?
    @State private var selectedDataPoints: SelectedDataPoints?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.context) var context

    private var valueFormatter: StatsValueFormatter {
        StatsValueFormatter(metric: data.metric)
    }

    private var currentAverage: Double {
        guard !data.currentData.isEmpty else { return 0 }
        return Double(data.currentTotal) / Double(data.currentData.count)
    }

    var body: some View {
        Chart {
            currentPeriodMarks
            previousPeriodMarks
            averageLine
            significantPointAnnotations
            selectionIndicatorMarks
        }
        .chartXAxis { xAxis }
        .chartYAxis { yAxis }
        .chartYScale(domain: yAxisDomain)
        .chartLegend(.hidden)
        .environment(\.timeZone, context.timeZone)
        .chartXSelection(value: $selectedDate)
        .animation(.spring, value: ObjectIdentifier(data))
        .onChange(of: selectedDate) {
            selectedDataPoints = SelectedDataPoints.compute(for: $0, data: data)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement()
        .accessibilityLabel(Strings.Accessibility.chartContainer)
        .accessibilityHint(Strings.Accessibility.viewChartData)
    }

    // MARK: - Chart Marks

    @ChartContentBuilder
    private var currentPeriodMarks: some ChartContent {
        ForEach(data.currentData) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value),
                series: .value("Period", "Current")
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        data.metric.primaryColor.opacity(colorScheme == .light ? 0.15 : 0.25),
                        data.metric.primaryColor.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.linear)

            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value),
                series: .value("Period", "Current")
            )
            .foregroundStyle(data.metric.primaryColor)
            .lineStyle(StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round
            ))
            .interpolationMethod(.linear)
        }
    }

    @ChartContentBuilder
    private var previousPeriodMarks: some ChartContent {
        ForEach(data.mappedPreviousData) { point in
            // Important: AreaMark is needed for smooth animation
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value),
                series: .value("Period", "Previous")
            )
            .foregroundStyle(Color.clear)
            .interpolationMethod(.linear)

            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value),
                series: .value("Period", "Previous")
            )
            .foregroundStyle(Color.secondary.opacity(0.8))
            .lineStyle(StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round,
                dash: [5, 6]
            ))
            .interpolationMethod(.linear)
        }
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
    private var significantPointAnnotations: some ChartContent {
        if let maxPoint = data.significantPoints.currentMax, data.currentData.count > 0 {
            PointMark(
                x: .value("Date", maxPoint.date),
                y: .value("Value", maxPoint.value)
            )
            .foregroundStyle(data.metric.primaryColor)
            .symbolSize(60)
            .annotation(position: .top, spacing: 4) {
                SignificantPointAnnotation(value: maxPoint.value, metric: data.metric)
                    .opacity(selectedDate == nil ? 1 : 0)
            }
            .opacity(selectedDate == nil ? 1 : 0)
        }
    }

    @ChartContentBuilder
    private var selectionIndicatorMarks: some ChartContent {
        if let selectedDataPoints {
            if let currentPoint = selectedDataPoints.current {
                RuleMark(x: .value("Selected", currentPoint.date))
                    .foregroundStyle(Color.secondary.opacity(0.33))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .offset(yStart: 28)
                    .zIndex(1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        tooltipView
                    }

                PointMark(
                    x: .value("Date", currentPoint.date),
                    y: .value("Value", currentPoint.value)
                )
                .foregroundStyle(data.metric.primaryColor)
                .symbolSize(80)
            } else if let previousPoint = selectedDataPoints.previous {
                RuleMark(x: .value("Selected", previousPoint.date))
                    .foregroundStyle(Color.secondary.opacity(0.33))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .offset(yStart: 28)
                    .zIndex(1)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        tooltipView
                    }

                PointMark(
                    x: .value("Date", previousPoint.date),
                    y: .value("Value", previousPoint.value)
                )
                .foregroundStyle(Color.secondary)
                .symbolSize(60)
            }
        }
    }

    // MARK: - Axis Configuration

    private var xAxis: some AxisContent {
        AxisMarks { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    ChartAxisDateLabel(date: date, granularity: data.granularity)
                }
            }
        }
    }

    private var yAxis: some AxisContent {
        AxisMarks { value in
            if let value = value.as(Int.self) {
                AxisGridLine()
                    .foregroundStyle(Color(.opaqueSeparator).opacity(0.5))

                AxisValueLabel {
                    Text(valueFormatter.format(value: value, context: .compact))
                        .font(.caption2.weight(.medium)).tracking(-0.1)
                        .foregroundColor(.secondary)
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
            return data.maxValue...0 // Just in case; should never happend
        }
        // Add some padding above the max value
        let padding = max(Int(Double(data.maxValue) * 0.66), 1)
        return 0...(data.maxValue + padding)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var tooltipView: some View {
        if let selectedPoints = selectedDataPoints {
            ChartValueTooltipView(
                selectedPoints: selectedPoints,
                metric: data.metric,
                granularity: data.granularity
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        LineChartView(
            data: ChartData.mock(
                metric: .views,
                granularity: .day,
                range: Calendar.demo.makeDateRange(for: .last7Days)
            )
        )
        .frame(height: 250)
        .padding()

        LineChartView(
            data: ChartData.mock(
                metric: .timeOnSite,
                granularity: .month,
                range: Calendar.demo.makeDateRange(for: .thisYear)
            )
        )
        .frame(height: 250)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
