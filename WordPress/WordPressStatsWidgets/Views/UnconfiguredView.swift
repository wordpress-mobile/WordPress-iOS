import SwiftUI

struct UnconfiguredView: View {

    var timelineEntry: StatsWidgetEntry

    var body: some View {
        Text(unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    var unconfiguredMessage: LocalizedString {
        switch timelineEntry {
        case .loggedOut(let widgetKind):
            switch widgetKind {
            case .today:
                return LocalizableStrings.unconfiguredViewTodayTitle
            case .allTime:
                return LocalizableStrings.unconfiguredViewAllTimeTitle
            case .thisWeek:
                return LocalizableStrings.unconfiguredViewThisWeekTitle
            }
        case .noSite(let widgetKind):
            switch widgetKind {
            case .today:
                return LocalizableStrings.noSiteViewTodayTitle
            case .allTime:
                return LocalizableStrings.noSiteViewAllTimeTitle
            case .thisWeek:
                return LocalizableStrings.noSiteViewThisWeekTitle
            }
        case .noData(let widgetKind):
            switch widgetKind {
            case .today:
                return LocalizableStrings.noDataViewTodayTitle
            case .allTime:
                return LocalizableStrings.noDataViewAllTimeTitle
            case .thisWeek:
                return LocalizableStrings.noDataViewThisWeekTitle
            }
        default:
            return LocalizableStrings.noDataViewTitle
        }
    }
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView(timelineEntry: .loggedOut(.today))
    }
}
