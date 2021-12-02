import SwiftUI

struct UnconfiguredView: View {

    var widgetKind: StatsWidgetKind

    var body: some View {
        Text(unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    var unconfiguredMessage: LocalizedString {
        switch widgetKind {
        case .today:
            return LocalizableStrings.unconfiguredViewTodayTitle
        case .allTime:
            return LocalizableStrings.unconfiguredViewAllTimeTitle
        case .thisWeek:
            return LocalizableStrings.unconfiguredViewThisWeekTitle
        case .noStats:
            return LocalizableStrings.noDataViewTitle
        }
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView(widgetKind: .today)
    }
}
