import Foundation
import CoreData


public class PublicizeConnectionStatsRecordValue: StatsRecordValue {
    public var iconURL: URL? {
        guard let url = iconURLString as String? else {
            return nil
        }
        return URL(string: url)
    }
}
