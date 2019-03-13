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


extension StatsPublicizeInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        return publicizeServices.compactMap {
            let value = PublicizeConnectionStatsRecordValue(context: context)

            value.name = $0.name
            value.followersCount = Int64($0.followers)
            value.iconURLString = $0.iconURL?.absoluteString

            return value
        }
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .publicizeConnection
    }
}
