import SwiftUI
import Charts

struct BarChartView: View {
    let data: ChartData
    @Binding var selectedBarDate: Date?

    @State private var selectedDataPoints: SelectedDataPoints?
    @State private var isDragging = false

    private var tappedDataPoint: DataPoint? {
        guard let selectedBarDate else { return nil }
        return data.currentData.first { $0.date == selectedBarDate }
    }

    init(data: ChartData, selectedBarDate: Binding<Date?> = .constant(nil)) {
        self.data = data
        self._selectedBarDate = selectedBarDate
    }

    @Environment(\.context) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.showComparison) private var showComparison

    private var valueFormatter: StatsValueFormatter {
        StatsValueFormatter(metric: data.metric)
    }

    private var currentAverage: Double {
        guard !data.currentData.isEmpty else { return 0 }
        return Double(data.currentTotal) / Double(data.currentData.count)
    }

    var body: some View {
        Chart {
            if showComparison {
                previousPeriodBars
            }
            currentPeriodBars
            averageLine
            significantPointAnnotations
            tappedBarAnnotation
            selectionIndicatorMarks
        }
        .chartXAxis { xAxis }
        .chartYAxis { yAxis }
        .chartXScale(domain: xAxisDomain)
        .chartYScale(domain: yAxisDomain)
        .chartLegend(.hidden)
        .environment(\.timeZone, context.timeZone)
        .animation(.spring, value: ObjectIdentifier(data))
        .animation(.snappy, value: selectedBarDate)
        .chartOverlay { proxy in
            makeGesturesOverlayView(proxy: proxy)
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
            let isIncomplete = context.calendar.isIncompleteDataPeriod(for: point.date, granularity: data.granularity)
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component, calendar: context.calendar),
                y: .value("Value", point.value),
                width: .automatic
            )
            .foregroundStyle(isIncomplete ? AnyShapeStyle(incompleteBarPattern) : AnyShapeStyle(barGradient))
            .cornerRadius(5)
            .opacity(getOpacityForPeriodBar(for: point))
        }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [data.metric.primaryColor, lighten(data.metric.primaryColor)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// A tiling diagonal-stripe pattern for today's incomplete bar.
    private var incompleteBarPattern: ImagePaint {
        let color = UIColor(data.metric.primaryColor)
        let tileSize: CGFloat = 10
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileSize, height: tileSize))
        let image = renderer.image { ctx in
            color.withAlphaComponent(0.33).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: tileSize, height: tileSize))

            let cg = ctx.cgContext
            cg.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
            cg.setLineWidth(1.5)
            // Three parallel lines for seamless tiling
            cg.move(to: CGPoint(x: -tileSize, y: tileSize))
            cg.addLine(to: CGPoint(x: tileSize, y: -tileSize))
            cg.move(to: CGPoint(x: 0, y: tileSize))
            cg.addLine(to: CGPoint(x: tileSize, y: 0))
            cg.move(to: CGPoint(x: 0, y: tileSize * 2))
            cg.addLine(to: CGPoint(x: tileSize * 2, y: 0))
            cg.strokePath()
        }
        return ImagePaint(image: Image(uiImage: image), scale: 1)
    }

    private func lighten(_ color: Color) -> Color {
        if #available(iOS 18, *) {
            color.mix(with: Color(.systemBackground), by: colorScheme == .light ? 0.2 : 0.1)
        } else {
            color.opacity(0.5)
        }
    }

    private func getOpacityForPeriodBar(for point: DataPoint) -> CGFloat {
        if let tappedDataPoint, tappedDataPoint.id == point.id {
            return 1.0
        }
        guard let selectedDataPoints else {
            if tappedDataPoint != nil {
                return 0.15
            }
            return 1
        }
        return (selectedDataPoints.current?.id == point.id || selectedDataPoints.previous?.id == point.id) ? 1.0 : 0.25
    }

    @ChartContentBuilder
    private var previousPeriodBars: some ChartContent {
        ForEach(data.mappedPreviousData) { point in
            BarMark(
                x: .value("Date", point.date, unit: data.granularity.component, calendar: context.calendar),
                y: .value("Value", point.value),
                width: .automatic,
                stacking: .unstacked
            )
            .foregroundStyle(Color.secondary.opacity(0.25))
            .cornerRadius(5)
            .opacity(getOpacityForPeriodBar(for: point))
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
        if tappedDataPoint == nil, let maxPoint = data.significantPoints.currentMax, data.currentData.count > 0 {
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
    private var tappedBarAnnotation: some ChartContent {
        if let tappedDataPoint, selectedDataPoints == nil {
            PointMark(
                x: .value("Date", tappedDataPoint.date, unit: data.granularity.component, calendar: context.calendar),
                y: .value("Value", tappedDataPoint.value)
            )
            .opacity(0)
            .annotation(position: .top, spacing: 8) {
                SignificantPointAnnotation(
                    value: tappedDataPoint.value,
                    metric: data.metric
                )
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
                    .offset(yStart: 48)
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
                    .offset(yStart: 48)
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
        ChartHelper.makeXAxis(
            domain: xAxisDomain,
            granularity: data.granularity,
            calendar: context.calendar
        )
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

    private var xAxisDomain: ClosedRange<Date> {
        ChartHelper.xAxisDomain(for: data, calendar: context.calendar)
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
        let padding = max(Int(Double(data.maxValue) * 0.33), 1)
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
                }
            )
        }
    }

    private func handleTapGesture(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        // Only handle tap if not dragging or long pressing
        guard !isDragging else { return }

        guard let selection = getSelectedDataPoints(at: location, proxy: proxy, geometry: geometry),
              let point = selection.current ?? selection.previous else {
            selectedBarDate = nil
            return
        }
        selectedBarDate = (selectedBarDate == point.date) ? nil : point.date
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
        // `proxy.value(atX:)` returns a precise date at the tap location.
        // Resolve it to the start of the containing calendar period so it
        // matches data point dates (which are period starts).
        guard let periodStart = context.calendar.dateInterval(of: data.granularity.component, for: date)?.start else {
            return nil
        }
        return SelectedDataPoints.compute(for: periodStart, data: data)
    }
}

// MARK: - Preview
#if DEBUG

#Preview {
    ScrollView {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 350, maximum: 450), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(ChartData.previewExamples) { example in
                previewCard(example.title) {
                    BarChartView(data: example.data)
                        .environment(\.showComparison, example.showComparison)
                }
            }
        }
        .padding()
    }
    .background(Constants.Colors.background)
}

private func previewCard<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        content()
            .padding(.horizontal)
            .frame(height: 220)
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color(.separator), lineWidth: 0.5)
    )
}

#endif
