import SwiftUI
import WidgetKit

struct ListStatsView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let viewData: ListViewData

    private var maxNumberOfLines: Int {
        switch family {
        case .systemMedium:
            return Constants.mediumSizeRows
        case .systemLarge:
            return Constants.largeSizeRows
        default:
            return 0
        }
    }

    private var displayData: [ThisWeekWidgetDay] {

        maxNumberOfLines < viewData.items.count ? Array(viewData.items.prefix(maxNumberOfLines)) : viewData.items
    }

    var body: some View {
        VStack {
            FlexibleCard(axis: .horizontal, title: viewData.widgetTitle, value: .description(viewData.siteName))
                .padding(.bottom, Constants.titleBottomPadding)
            ForEach(Array(displayData.enumerated()), id: \.element) { index, item in
                ListRow(date: item.date, percentValue: item.dailyChangePercent, value: item.viewsCount)
                if index != displayData.count - 1 {
                    Divider().padding(.top, 0)
                }
            }
        }
    }
}

private extension ListStatsView {
    enum Constants {
        static let mediumSizeRows = 3
        static let largeSizeRows = 7

        static let titleBottomPadding: CGFloat = 8.0
    }
}
