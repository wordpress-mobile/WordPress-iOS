import WidgetKit

protocol HomeWidgetData: Codable {

    associatedtype WidgetStats

    var siteID: Int { get }
    var siteName: String { get }
    var url: String { get }
    var timeZone: TimeZone { get }
    var date: Date { get }
    var stats: WidgetStats { get }
}
