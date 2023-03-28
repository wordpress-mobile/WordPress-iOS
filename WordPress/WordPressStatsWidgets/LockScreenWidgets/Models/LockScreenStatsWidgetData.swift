import Foundation

protocol LockScreenStatsWidgetData {
    var siteName: String { get }
    var widgetURL: URL? { get }
    var views: Int? { get }
    var date: Date { get }
}
