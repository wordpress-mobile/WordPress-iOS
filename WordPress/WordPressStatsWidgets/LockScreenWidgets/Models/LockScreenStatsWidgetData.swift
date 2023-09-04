import Foundation

protocol LockScreenStatsWidgetData {
    var siteName: String { get }
    var statsURL: URL? { get }
    var views: Int? { get }
    var comments: Int? { get }
    var date: Date { get }
}
