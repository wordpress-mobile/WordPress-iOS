import SwiftUI
import JetpackStatsWidgetsCore

struct ListViewData {

    let widgetTitle: LocalizedString
    let siteName: String
    let items: [ThisWeekWidgetDay]

    let statsURL: URL?
}
