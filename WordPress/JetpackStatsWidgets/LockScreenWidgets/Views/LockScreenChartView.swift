import SwiftUI
import WidgetKit
import Charts

@available(iOS 16.0, *)
struct LockScreenChartView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenChartViewModel

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack() {
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer(minLength: 0)
                    LockScreenSiteTitleView(title: dateInterval(viewModel.columns), alignment: .trailing, isIconShown: false)
                }
                Spacer(minLength: 0)
                if isChartShown {
                    Text(String(format: LocalizableStrings.chartViewsLabel, viewModel.total.abbreviatedString()))
                        .font(.system(size: LockScreenFieldView.ValueFontSize.small, weight: .heavy))
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 4)
                    ZStack {
                        Chart {
                            ForEach(viewModel.columns, id: \.self) { column in
                                AreaMark(
                                    x: .value(LocalizableStrings.chartXAxisLabel, column.date),
                                    y: .value(LocalizableStrings.chartYAxisLabel, column.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                        .mask(LinearGradient(gradient: Gradient(stops: [
                            .init(color: .black, location: 0.75),
                            .init(color: .clear, location: 1)
                        ]), startPoint: .top, endPoint: .bottom))

                        Chart {
                            ForEach(viewModel.columns, id: \.self) { column in
                                LineMark(
                                    x: .value(LocalizableStrings.chartXAxisLabel, column.date),
                                    y: .value(LocalizableStrings.chartYAxisLabel, column.value)
                                )
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                    }
                } else {
                    LockScreenFieldView(title: viewModel.emptyChartTitle, value: viewModel.total.abbreviatedString())
                }
            }
        }
    }

    private var isChartShown: Bool {
        viewModel.total > 0 && viewModel.columns.count > 0
    }

    private func dateInterval(_ columns: [LockScreenChartViewModel.Column]) -> String {
        guard columns.count > 1 else { return "" }

        let dates = columns.map { $0.date }.sorted { $0 < $1 }

        return (dates[0]..<dates[dates.count - 1]).formatted(
            Date.IntervalFormatStyle()
                .weekday(.abbreviated)
        )
    }
}

@available(iOS 16.0, *)
struct LockScreenChartView_Previews: PreviewProvider {
    static let viewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        valueTitle: LocalizableStrings.chartViewsLabel,
        emptyChartTitle: "Views This Week",
        columns: generateWeekDates().enumerated().map {
            LockScreenChartViewModel.Column(date: $1, value: $0 == 3 ? 0 : $0 + 10 + 3 * ($0 % 2))
        },
        updatedTime: Date()
    )

    static let incompleteViewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        valueTitle: LocalizableStrings.chartViewsLabel,
        emptyChartTitle: "Views This Week",
        columns: generateWeekDates()[0...3].enumerated().map {
            LockScreenChartViewModel.Column(date: $1, value: $0 + 10 + 3 * ($0 % 2))
        },
        updatedTime: Date()
    )

    static let emptyViewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        valueTitle: LocalizableStrings.chartViewsLabel,
        emptyChartTitle: "Views This Week",
        columns: [],
        updatedTime: Date()
    )

    static func generateWeekDates() -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: Date(timeIntervalSince1970: -60 * 60 * 60)) {
                dates.append(date)
            }
        }
        return dates
    }

    static var previews: some View {
        Group {
            LockScreenChartView(
                viewModel: LockScreenChartView_Previews.viewModel
            )
            LockScreenChartView(
                viewModel: LockScreenChartView_Previews.incompleteViewModel
            )
            LockScreenChartView(
                viewModel: LockScreenChartView_Previews.emptyViewModel
            )
        }
        .previewContext(
            WidgetPreviewContext(family: .accessoryRectangular)
        )
    }
}
