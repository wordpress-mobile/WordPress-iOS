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
            return AppConfiguration.Widget.Localization.unconfiguredViewTodayTitle
        case .allTime:
            return AppConfiguration.Widget.Localization.unconfiguredViewAllTimeTitle
        case .thisWeek:
            return AppConfiguration.Widget.Localization.unconfiguredViewThisWeekTitle
        case .noSite:
            return LocalizableStrings.noSiteViewTitle
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
