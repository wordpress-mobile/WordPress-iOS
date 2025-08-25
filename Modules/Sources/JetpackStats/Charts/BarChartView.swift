import SwiftUI
import Charts

struct BarChartView: View {
    let data: ChartData

    @State private var selectedDate: Date?
    @State private var selectedDataPoints: SelectedDataPoints?

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
            previousPeriodBars
            currentPeriodBars
            averageLine
            significantPointAnnotations
            selectionIndicatorMarks
        }
        .chartXAxis { xAxis }
        .chartYAxis { yAxis }
        .chartYScale(domain: yAxisDomain)
        .chartLegend(.hidden)
        .environment(\.timeZone, context.timeZone)
        .modifier(ChartSelectionModifier(selection: $selectedDate))
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
    private var currentPeriodBars: some ChartContent {
        ForEach(data.currentData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component),
                y: .value("Value", point.value),
                width: .automatic
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        data.metric.primaryColor,
                        data.metric.primaryColor.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
            .opacity(getOpacityForCurrentPeriodBar(for: point))
        }
    }

    private func getOpacityForCurrentPeriodBar(for point: DataPoint) -> CGFloat {
        guard let selectedDataPoints else {
            let isIncomplete = context.calendar.isIncompleteDataPeriod(for: point.date, granularity: data.granularity)
            return isIncomplete ? 0.5 : 1
        }
        return selectedDataPoints.current?.id == point.id ? 1.0 : 0.5
    }

    @ChartContentBuilder
    private var previousPeriodBars: some ChartContent {
        ForEach(data.mappedPreviousData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component),
                y: .value("Value", point.value),
                width: .automatic,
                stacking: .unstacked
            )
            .foregroundStyle(Color.secondary)
            .cornerRadius(6)
            .opacity(shouldHighlightPreviousDataPoint(point) ? 0.5 : 0.2)
        }
    }

    private func shouldHighlightPreviousDataPoint(_ dataPoint: DataPoint) -> Bool {
        guard let selectedDataPoints else {
            return false
        }
        return selectedDataPoints.current == nil && selectedDataPoints.previous?.id == dataPoint.id
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
                x: .value("Date", maxPoint.date, unit: data.granularity.component),
                y: .value("Value", maxPoint.value)
            )
            .opacity(0)
            .annotation(position: .top, spacing: 8) {
                SignificantPointAnnotation(
                    value: maxPoint.value,
                    metric: data.metric
                )
                // Important for drag selection to work correctly.
                .opacity(selectedDate == nil ? 1 : 0)
            }
        }
    }

    @ChartContentBuilder
    private var selectionIndicatorMarks: some ChartContent {
        if #available(iOS 17.0, *), let selectedDataPoints {
            if let currentPoint = selectedDataPoints.current {
                RuleMark(x: .value("Selected", currentPoint.date))
                    .foregroundStyle(Color.clear)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .offset(yStart: 32)
                    .zIndex(3)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        tooltipView
                    }
            } else if let previousPoint = selectedDataPoints.previous {
                RuleMark(x: .value("Selected", previousPoint.date))
                    .foregroundStyle(Color.clear)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .offset(yStart: 32)
                    .zIndex(3)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        tooltipView
                    }
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
        BarChartView(
            data: ChartData.mock(
                metric: .visitors,
                granularity: .day,
                range: Calendar.demo.makeDateRange(for: .last7Days)
            )
        )
        .frame(height: 250)
        .padding()

        BarChartView(
            data: ChartData.mock(
                metric: .likes,
                granularity: .month,
                range: Calendar.demo.makeDateRange(for: .thisYear)
            )
        )
        .frame(height: 250)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
