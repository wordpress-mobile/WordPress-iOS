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

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let connections = statsRecordValues as? [PublicizeConnectionStatsRecordValue]
            else {
                return nil
        }

        self = StatsPublicizeInsight(publicizeServices: connections.compactMap {
            guard let name = $0.name else {
                return nil
            }

            return StatsPublicizeService(name: name, followers: Int($0.followersCount), iconURL: $0.iconURL)
        })

    }

    static var recordType: StatsRecordType {
        return .publicizeConnection
    }
}
