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

    private var shouldShowCurrentTimeBoundary: Bool {
        guard let lastDataPoint = data.currentData.last,
              let firstDataPoint = data.currentData.first,
              let lastDate = data.currentData.last?.date else {
            return false
        }
        return context.calendar.isDateInToday(lastDate) || (firstDataPoint.date...lastDataPoint.date).contains(.now)
    }

    var body: some View {
        Chart {
            currentPeriodMarks
            previousPeriodMarks
            currentTimeBoundaryMark
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
    private var currentTimeBoundaryMark: some ChartContent {
        if shouldShowCurrentTimeBoundary,
           let lastDataPoint = data.currentData.last {
            RuleMark(
                x: .value("Now", lastDataPoint.date),
                yStart: .value("Start", 0),
                yEnd: .value("End", lastDataPoint.value)
            )
            .foregroundStyle(data.metric.primaryColor.opacity(0.33))
            .lineStyle(StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                dash: [5, 5]
            ))
        }
    }
    
    @ChartContentBuilder
    private var significantPointAnnotations: some ChartContent {
        if selectedDate == nil,
           let maxPoint = data.significantPoints.currentMax,
           data.currentData.count > 0 {
            PointMark(
                x: .value("Date", maxPoint.date),
                y: .value("Value", maxPoint.value)
            )
            .foregroundStyle(data.metric.primaryColor)
            .symbolSize(60)
            .annotation(position: .top, spacing: 4) {
                Text(valueFormatter.format(value: maxPoint.value, context: .compact))
                    .fixedSize() // Important
                    .font(.caption.weight(.semibold))
                    .foregroundColor(data.metric.primaryColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        ZStack {
                            Capsule()
                                .fill(Color(.systemBackground).opacity(0.75))
                            Capsule()
                                .fill(data.metric.primaryColor.opacity(0.1))
                        }
                    }
            }
        }
    }

    @ChartContentBuilder
    private var selectionIndicatorMarks: some ChartContent {
        if #available(iOS 17.0, *),
           let selectedDate,
           let selectedPoints = selectedDataPoints {

            RuleMark(x: .value("Selected", selectedDate))
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

            if let currentPoint = selectedPoints.current {
                PointMark(
                    x: .value("Date", currentPoint.date),
                    y: .value("Value", currentPoint.value)
                )
                .foregroundStyle(data.metric.primaryColor)
                .symbolSize(80)
            }

            if let previousPoint = selectedPoints.previous {
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
                        .font(.caption2.weight(.medium))
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
                currentPoint: selectedPoints.current,
                previousPoint: selectedPoints.previous,
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
