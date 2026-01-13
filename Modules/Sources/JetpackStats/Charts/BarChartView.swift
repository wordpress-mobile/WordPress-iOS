import SwiftUI
import Charts

struct BarChartView: View {
    let data: ChartData
    var onDateSelected: ((Date) -> Void)? = nil

    @State private var selectedDataPoints: SelectedDataPoints?
    @State private var isDragging = false
    @State private var tappedDataPoint: DataPoint?

    @Environment(\.context) var context
    @Environment(\.colorScheme) var colorScheme

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
        .animation(.spring, value: ObjectIdentifier(data))
        .chartOverlay { proxy in
            makeGesturesOverlayView(proxy: proxy)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement()
        .accessibilityLabel(Strings.Accessibility.chartContainer)
        .accessibilityHint(Strings.Accessibility.viewChartData)
        .onChange(of: ObjectIdentifier(data)) {
            tappedDataPoint = nil
        }
    }

    // MARK: - Chart Marks

    @ChartContentBuilder
    private var currentPeriodBars: some ChartContent {
        ForEach(data.currentData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component, calendar: context.calendar),
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
            .opacity(getOpacityForCurrentPeriodBar(for: point))
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

    private func getOpacityForCurrentPeriodBar(for point: DataPoint) -> CGFloat {
        if let tappedDataPoint, tappedDataPoint.id == point.id {
            return 1.0
        }
        guard let selectedDataPoints else {
            // If there's a tapped point, dim other bars
            if tappedDataPoint != nil {
                return 0.5
            }
            // If no selection and not tapped, check if data is incomplete
            let isIncomplete = context.calendar.isIncompleteDataPeriod(for: point.date, granularity: data.granularity)
            return isIncomplete ? 0.5 : 1
        }
        return selectedDataPoints.current?.id == point.id ? 1.0 : 0.5
    }

    @ChartContentBuilder
    private var previousPeriodBars: some ChartContent {
        ForEach(data.mappedPreviousData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component, calendar: context.calendar),
                y: .value("Value", point.value),
                width: barWidth,
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
                x: .value("Date", maxPoint.date, unit: data.granularity.component, calendar: context.calendar),
                y: .value("Value", maxPoint.value)
            )
            .opacity(0)
            .annotation(position: .top, spacing: 8) {
                SignificantPointAnnotation(
                    value: maxPoint.value,
                    metric: data.metric
                )
                // Important for drag selection to work correctly.
                .opacity(selectedDataPoints == nil ? 1 : 0)
            }
        }
    }

    @ChartContentBuilder
    private var selectionIndicatorMarks: some ChartContent {
        if let selectedDataPoints {
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
        if data.currentData.count == 1 {
            // A quick workaround to make this look more acceptible
            AxisMarks(values: .stride(by: data.granularity.component, count: 1, calendar: context.calendar)) { value in
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

    // MARK: - Gestures

    private func makeGesturesOverlayView(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            ChartGestureOverlay(
                onTap: { location in
                    handleTapGesture(at: location, proxy: proxy, geometry: geometry)
                },
                onInteractionUpdate: { location in
                    isDragging = true
                    selectedDataPoints = getSelectedDataPoints(at: location, proxy: proxy, geometry: geometry)
                },
                onInteractionEnd: {
                    isDragging = false
                    selectedDataPoints = nil
                    tappedDataPoint = nil
                }
            )
        }
    }

    private func handleTapGesture(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        // Only handle tap if not dragging or long pressing
        guard !isDragging else { return }

        guard let onDateSelected,
              data.granularity != .hour,
              let selection = getSelectedDataPoints(at: location, proxy: proxy, geometry: geometry),
              selection.current?.value != 0 || selection.previous?.value != 0 else {
            // Clear selection if tapping on empty area
            tappedDataPoint = nil
            return
        }
        tappedDataPoint = selection.current ?? selection.previous
        if let date = tappedDataPoint?.date {
            onDateSelected(date)
        }
    }

    private func getSelectedDataPoints(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> SelectedDataPoints? {
        guard let frame = proxy.plotFrame else {
            return nil
        }

        let origin = geometry[frame].origin
        let location = CGPoint(
            x: location.x - origin.x,
            y: location.y - origin.y
        )
        guard let date: Date = proxy.value(atX: location.x) else {
            return nil
        }
        // Calling `proxy.value(atX: location.x)` returns dates with a second
        // precision. But the data points are represented using the start of the
        // period. The chart needs to offset the selection so that
        // `SelectedDataPoints.compute` correctly finds the closest one.
        let interval: TimeInterval = {
            let now = Date()
            let interval = context.calendar.date(byAdding: data.granularity.component, value: 1, to: now)
            return (interval ?? now).timeIntervalSince(now)
        }()

        let offsetDate = date.addingTimeInterval(-(interval / 4))
        return SelectedDataPoints.compute(for: offsetDate, data: data)
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
