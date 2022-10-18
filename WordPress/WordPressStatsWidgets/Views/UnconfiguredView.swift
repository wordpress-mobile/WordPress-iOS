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
        switch (widgetKind, AppConfiguration.isJetpack) {
        case (.today, false):
            return LocalizableStrings.unconfiguredViewTodayTitle
        case (.allTime, false):
            return LocalizableStrings.unconfiguredViewAllTimeTitle
        case (.thisWeek, false):
            return LocalizableStrings.unconfiguredViewThisWeekTitle
        case (.today, true):
            return LocalizableStrings.unconfiguredViewJetpackTodayTitle
        case (.allTime, true):
            return LocalizableStrings.unconfiguredViewJetpackAllTimeTitle
        case (.thisWeek, true):
            return LocalizableStrings.unconfiguredViewJetpackThisWeekTitle
        case (.noStats, _):
            return LocalizableStrings.noDataViewTitle
        }
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView(widgetKind: .today)
    }
}
