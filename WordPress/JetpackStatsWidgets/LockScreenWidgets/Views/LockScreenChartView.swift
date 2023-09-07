import SwiftUI
import WidgetKit
import Charts

@available(iOS 16.0, *)
struct LockScreenChartView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    let viewModel: LockScreenChartViewModel

    var body: some View {
        if family == .accessoryRectangular {
            ZStack {
                AccessoryWidgetBackground()
                VStack(alignment: .leading) {
                    LockScreenSiteTitleView(title: viewModel.siteName)
                    Spacer(minLength: 0)
                    if isChartShown {
                        Text(String(format: LocalizableStrings.chartViewsLabel, viewModel.total.abbreviatedString()))
                            .font(.system(size: LockScreenFieldView.ValueFontSize.small, weight: .bold))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.6)
                        Spacer(minLength: 0)
                        Chart {
                            ForEach(viewModel.columns, id: \.self) { column in
                                BarMark(
                                    x: .value(LocalizableStrings.chartXAxisLabel, column.date),
                                    y: .value(LocalizableStrings.chartYAxisLabel, column.value)
                                )
                                .cornerRadius(6)
                            }
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                    } else {
                        LockScreenFieldView(title: viewModel.title, value: viewModel.total.abbreviatedString())
                    }
                }
                .padding(
                    EdgeInsets(top: 4, leading: 8, bottom: isChartShown ? 0 : 4, trailing: 8)
                )
            }
            .cornerRadius(8)
        } else {
            Text("Not implemented for widget family \(family.debugDescription)")
        }
    }

    private var isChartShown: Bool {
        viewModel.total > 0 && viewModel.columns.count == 14
    }
}

@available(iOS 16.0, *)
struct LockScreenChartView_Previews: PreviewProvider {
    static let viewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        title: "Views This Week",
        columns: Array<Int>(0...13).map {
            LockScreenChartViewModel.Column(date: Date(timeIntervalSinceNow: -Double($0)), value: $0 + 10 + 3 * ($0 % 2))
            },
        updatedTime: Date()
    )

    static let incompleteViewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        title: "Views This Week",
        columns: Array<Int>(0...8).map {
            LockScreenChartViewModel.Column(date: Date(timeIntervalSinceNow: -Double($0)), value: $0 + 10 + 3 * ($0 % 2))
            },
        updatedTime: Date()
    )

    static let emptyViewModel = LockScreenChartViewModel(
        siteName: "My WordPress Site",
        title: "Views This Week",
        columns: [],
        updatedTime: Date()
    )

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
