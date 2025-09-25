import SwiftUI
import WordPressUI
import UniformTypeIdentifiers

struct ChartDataListView: View {
    let data: ChartData
    let dateRange: StatsDateRange

    @Environment(\.context) var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.step4) {
                summaryCard(for: data, metric: data.metric)
                    .padding(.vertical, Constants.step2)
                    .padding(.horizontal, Constants.step3)
                    .background(Constants.Colors.background.opacity(0.66))
                    .cardStyle()
                    .padding(.top, Constants.step2)
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)

                dataItemsView(for: data, metric: data.metric)
                    .padding(.horizontal, Constants.step1)
            }
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .frame(maxWidth: horizontalSizeClass == .regular ? Constants.maxHortizontalWidth : .infinity)
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .background(Constants.Colors.secondaryBackground)
        .navigationTitle(Strings.ChartData.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if #available(iOS 26, *) {
                    SwiftUI.Button(role: .close) {
                        dismiss()
                    }
                } else {
                    SwiftUI.Button(Strings.Buttons.cancel) {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(
                        item: ChartDataCSVRepresentation(
                            data: data,
                            dateRange: dateRange,
                            context: context
                        ),
                        preview: SharePreview(
                            generateCSVFilename(),
                            image: Image(systemName: "doc.text")
                        )
                    ) {
                        Label(Strings.Buttons.downloadCSV, systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(Strings.Buttons.share)
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
                Text(metric.localizedTitle)
                    .font(.title3.weight(.medium))
                Text(context.formatters.dateRange.string(from: dateRange.dateInterval))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Metrics section
            HStack(alignment: .top, spacing: 0) {
                metricColumn(
                    label: Strings.ChartData.total,
                    value: formatter.format(value: chartData.currentTotal, context: .compact),
                    formatter: formatter
                )
                .padding(.trailing, Constants.step2)

                metricColumn(
                    label: Strings.ChartData.previous,
                    value: formatter.format(value: chartData.previousTotal, context: .compact),
                    formatter: formatter
                )
                .foregroundColor(.secondary)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Strings.ChartData.change.uppercased())
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 2) {
                        Text(trendViewModel.sign)
                            .font(.body.weight(.medium))

                        Text(formatter.format(value: abs(trendViewModel.currentValue - trendViewModel.previousValue), context: .compact))
                            .font(.title3.weight(.medium))
                            .padding(.trailing, 8)

                        Image(systemName: trendViewModel.systemImage)
                            .font(.footnote.weight(.medium))
                            .padding(.bottom, 1)

                        Text(trendViewModel.formattedPercentage)
                            .font(.title3.weight(.medium))
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
                .font(.title3.weight(.medium))
        }
    }

    private func generateCSVFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let metricName = data.metric.localizedTitle
            .replacingOccurrences(of: " ", with: "_")

        let dateRangeString = context.formatters.dateRange.string(from: dateRange.dateInterval)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "_")

        return "\(metricName)_\(dateRangeString)_\(dateString).csv"
    }

    private func dataItemsView(for chartData: ChartData, metric: SiteMetric) -> some View {
        let formatter = StatsValueFormatter(metric: metric)
        return VStack(alignment: .leading, spacing: Constants.step1) {
            VStack(alignment: .leading, spacing: Constants.step2) {
                Text(Strings.ChartData.detailedData)
                    .font(.subheadline.weight(.semibold))

                // Header
                HStack {
                    Text(Strings.ChartData.date)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Spacer()

                    Text(Strings.ChartData.value)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
            .padding(.horizontal)

            VStack(spacing: Constants.step1 / 2) {
                ForEach(chartData.currentData.reversed()) { point in
                    DataItemRow(
                        date: context.formatters.date.formatDate(point.date, granularity: chartData.granularity, context: .regular),
                        value: point.value,
                        maxValue: chartData.maxValue,
                        formatter: formatter,
                        metric: metric
                    )
                }
            }
        }
    }
}

// MARK: - Data Item Row

private struct DataItemRow: View {
    let date: String
    let value: Int
    let maxValue: Int
    let formatter: StatsValueFormatter
    let metric: SiteMetric

    var body: some View {
        HStack(spacing: 16) {
            Text(date)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(formatter.format(value: value))
                .font(.callout.weight(.medium))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            TopListItemBarBackground(value: value, maxValue: maxValue, barColor: metric.primaryColor)
        )
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
            data: ChartData(
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
            ),
            dateRange: Calendar.demo.makeDateRange(for: .last7Days)
        )
    }
}
