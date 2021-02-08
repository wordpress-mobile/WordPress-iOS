
import SwiftUI
import WidgetKit

struct ListRow: View {

    let date: Date
    let percentValue: Float
    let value: Int

    private var isToday: Bool {
        NSCalendar.current.isDateInToday(date)
    }

    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.positivePrefix = "+"
        return formatter
    }()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }()

    private var differenceBackgroundColor: Color {
        guard !isToday else {
            return Constants.neutralColor
        }
        return percentValue < 0 ? Constants.negativeColor : Constants.positiveColor
    }

    private var differenceLabelText: LocalizedStringKey {
        guard !isToday else {
            return LocalizableStrings.todayWidgetTitle
        }

        return LocalizedStringKey(dateFormatter.string(from: date))
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(differenceLabelText)
                .font(Constants.dateViewFont)
                .fontWeight(Constants.dateViewFontWeight)
                .foregroundColor(Constants.dateViewFontColor)
            Spacer()
            Text(value.abbreviatedString())
                .font(Constants.dataViewFont)
                .foregroundColor(Constants.dataViewFontColor)

            Text(percentFormatter.string(for: percentValue) ?? "0")

                .frame(minWidth: Constants.differenceViewMinWidth,
                       idealHeight: Constants.differenceViewIdealHeight,
                       alignment: Constants.differenceViewAlignment)
                .padding(Constants.differenceViewInsets)
                .font(Constants.differenceViewFont)
                .foregroundColor(Constants.differenceTextColor)
                .background(differenceBackgroundColor)
                .cornerRadius(Constants.differenceCornerRadius)
        }
        .frame(height: 20)
        .flipsForRightToLeftLayoutDirection(true)
    }
}

private extension ListRow {

    enum Constants {
        // difference view
        static let positiveColor = Color("Green50")
        static let negativeColor = Color("Red50")
        static let neutralColor = Color(UIColor.systemGray)
        static let differenceTextColor = Color.white

        static let differenceViewInsets = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        static let differenceViewMinWidth: CGFloat = 44.0
        static let differenceViewIdealHeight: CGFloat = 24.0
        static let differenceViewAlignment = Alignment.trailing

        static let differenceCornerRadius: CGFloat = 4.0

        static let differenceViewFont = Font.footnote
        // date view
        static let dateViewFont = Font.subheadline
        static let dateViewFontColor = Color(.label)
        static let dateViewFontWeight = Font.Weight.regular
        // data view
        static let dataViewFont = Font.caption
        static let dataViewFontColor = Color(.label)
    }
}

//struct ThisWeekRow_Previews: PreviewProvider {
//    static var previews: some View {
//        StatsListRow(day: ThisWeekWidgetDay(date: Date(), viewsCount: 130, dailyChangePercent: -0.22))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//    }
//}
