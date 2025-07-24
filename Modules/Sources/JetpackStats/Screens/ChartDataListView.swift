import SwiftUI

struct ChartDataListView: View {
    let chartDataDict: [SiteMetric: ChartData]
    let selectedMetric: SiteMetric?
    let dateRanges: StatsDateRange?

    @Environment(\.dismiss) private var dismiss

    @Environment(\.context) var context

    private var dateRangeFormatter: StatsDateRangeFormatter {
        context.formatters.dateRange
    }

    var body: some View {
        ScrollView {
            if let selectedType = selectedMetric,
               let chartData = chartDataDict[selectedType] {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard(for: chartData, metric: selectedType)
                        .padding()
                        .cardStyle()
                        .padding(.top)

                    dataItemsView(for: chartData, metric: selectedType)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
        }
        .background(Constants.Colors.background)
        .navigationTitle("Chart Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action to be implemented
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func summaryCard(for chartData: ChartData, metric: SiteMetric) -> some View {
        let formatter = StatsValueFormatter(metric: metric)
        let trendViewModel = TrendViewModel(
            currentValue: chartData.currentTotal,
            previousValue: chartData.previousTotal,
            metric: metric
        )

        return VStack(alignment: .leading, spacing: 16) {
            // Header section
            VStack(alignment: .leading, spacing: 2) {
                StatsCardTitleView(title: metric.localizedTitle, showChevron: true)

                if let dateRanges {
                    Text("\(dateRangeFormatter.string(from: dateRanges.dateInterval)) vs \(dateRangeFormatter.string(from: dateRanges.effectiveComparisonInterval))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Period comparison")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Metrics section
            HStack(alignment: .top, spacing: 24) {
                metricColumn(
                    label: "Value",
                    value: formatter.format(value: chartData.currentTotal, context: .compact),
                    formatter: formatter
                )

                metricColumn(
                    label: "Previous",
                    value: formatter.format(value: chartData.previousTotal, context: .compact),
                    formatter: formatter
                )
                .foregroundColor(.secondary)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("CHANGE")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 2) {
                        Text(trendViewModel.sign)
                            .font(.body.weight(.medium))

                        Text(formatter.format(value: abs(trendViewModel.currentValue - trendViewModel.previousValue), context: .compact))
                            .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                            .padding(.trailing, 14)

                        Image(systemName: trendViewModel.systemImage)
                            .font(Font.make(.recoleta, textStyle: .body, weight: .medium))
                            .padding(.bottom, 2)

                        Text(trendViewModel.formattedPercentage)
                            .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                    }
                    .foregroundStyle(trendViewModel.sentiment.foregroundColor)
                }
            }
            .lineLimit(1)
        }
    }

    private func metricColumn(label: String, value: String, formatter: StatsValueFormatter) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
        }
    }

    private func dataItemsView(for chartData: ChartData, metric: SiteMetric) -> some View {
        let formatter = StatsValueFormatter(metric: metric)

        let maxValue = chartData.currentData.map(\.value).max() ?? 1

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Detailed Data")
                    .font(.headline)

                // Header
                HStack {
                    Text("DATE")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Spacer()

                    Text("VALUE")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
            .padding(.horizontal)

            // Data items
            VStack(spacing: 8) {
                ForEach(Array(chartData.currentData.enumerated()), id: \.element.date) { index, currentPoint in
                    let previousValue = index < chartData.mappedPreviousData.count ? chartData.mappedPreviousData[index].value : 0
                    let change = currentPoint.value - previousValue
                    let changePercent = previousValue > 0 ? (Double(change) / Double(previousValue)) * 100 : 0

                    let previousDate = index < chartData.previousData.count ? chartData.previousData[index].date : nil

                    DataItemRow(
                        date: context.formatters.date.formatDate(currentPoint.date, granularity: chartData.granularity),
                        currentValue: currentPoint.value,
                        previousValue: previousValue,
                        previousDate: previousDate != nil ? context.formatters.date.formatDate(previousDate!, granularity: chartData.granularity) : nil,
                        change: change,
                        changePercent: changePercent,
                        maxValue: maxValue,
                        formatter: formatter,
                        metric: metric
                    )
                }
            }
        }
    }
}

// MARK: - Data Item Row

// TODO: reuse the code with the horizontal bar chart thingy
private struct DataItemRow: View {
    let date: String
    let currentValue: Int
    let previousValue: Int
    let previousDate: String?
    let change: Int
    let changePercent: Double
    let maxValue: Int
    let formatter: StatsValueFormatter
    let metric: SiteMetric

    @ScaledMetric(relativeTo: .body) private var valueColumnWidth: CGFloat = 60

    var body: some View {
        return HStack(spacing: 16) {
            Text(date)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(formatter.format(value: currentValue))
                    .font(.callout.weight(.medium))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            DataBarBackground(value: currentValue, maxValue: maxValue, metric: metric)
        )
    }
}

// MARK: - Data Bar Background

private struct DataBarBackground: View {
    let value: Int
    let maxValue: Int
    let metric: SiteMetric

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor)
                    .frame(width: barWidth(in: geometry))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
                Spacer(minLength: 0)
            }
        }
    }

    private var barColor: Color {
        metric.primaryColor.opacity(colorScheme == .light ? 0.09 : 0.5)
    }

    private func barWidth(in geometry: GeometryProxy) -> CGFloat {
        guard maxValue > 0 else {
            return 0
        }
        let value = geometry.size.width * CGFloat(value) / CGFloat(maxValue)
        return max(0, value)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        ChartDataListView(
            chartDataDict: [
                .views: ChartData(
                    metric: .views,
                    granularity: .day,
                    currentTotal: 3000,
                    currentData: [
                        DataPoint(date: Date(), value: 1000),
                        DataPoint(date: Date().addingTimeInterval(-86400), value: 1200),
                        DataPoint(date: Date().addingTimeInterval(-172800), value: 800)
                    ],
                    previousTotal: 2750,
                    previousData: [
                        DataPoint(date: Date().addingTimeInterval(-604800), value: 900),
                        DataPoint(date: Date().addingTimeInterval(-691200), value: 1100),
                        DataPoint(date: Date().addingTimeInterval(-777600), value: 750)
                    ],
                    mappedPreviousData: [
                        DataPoint(date: Date(), value: 900),
                        DataPoint(date: Date().addingTimeInterval(-86400), value: 1100),
                        DataPoint(date: Date().addingTimeInterval(-172800), value: 750)
                    ]
                )
            ],
            selectedMetric: .views,
            dateRanges: Calendar.demo.makeDateRange(for: .last7Days)
        )
    }
}
