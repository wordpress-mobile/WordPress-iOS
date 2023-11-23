import Foundation

public protocol HomeWidgetData: Codable {

    var siteID: Int { get }
    var siteName: String { get }
    var url: String { get }
    var timeZone: TimeZone { get }
    var date: Date { get }
    var statsURL: URL? { get }

    static var filename: String { get }
}
