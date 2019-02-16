import Foundation
import CoreData


public class ReferrerStatsRecordValue: StatsRecordValue {

    public var referrerURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public var iconURL: URL? {
        guard let url = iconURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}
