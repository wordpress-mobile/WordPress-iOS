import Foundation
import CoreData

public enum FollowersStatsType: Int16 {
    case email
    case dotCom
}

public class FollowersStatsRecordValue: StatsRecordValue {
    public var avatarURL: URL? {
        guard let url = avatarURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard FollowersStatsType(rawValue: type) != nil else {
            throw StatsCoreDataValidationError.invalidEnumValue
        }
    }
}

fileprivate extension FollowersStatsRecordValue {
    convenience init(context: NSManagedObjectContext, statsFollower: StatsFollower, type: FollowersStatsType) {
        self.init(context: context)

        self.type = type.rawValue
        self.name = statsFollower.name
        self.subscribedDate = statsFollower.subscribedDate as NSDate
        self.avatarURLString = statsFollower.avatarURL?.absoluteString
    }
}

extension StatsEmailFollowersInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let countRecordValue = FollowersCountStatsRecordValue(context: context)
        countRecordValue.count = Int64(emailFollowersCount)
        countRecordValue.type = FollowersStatsType.email.rawValue

        var records: [StatsRecordValue] = topEmailFollowers.map { FollowersStatsRecordValue(context: context, statsFollower: $0, type: .email) }
        records.append(countRecordValue)

        return records
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        let countInsights = statsRecordValues
            .compactMap { $0 as? FollowersCountStatsRecordValue }
            .filter { $0.type == FollowersStatsType.email.rawValue }

        guard let emailCountInsight = countInsights.first else {
            return nil
        }

        let followers: [StatsFollower] = statsRecordValues
            .compactMap { $0 as? FollowersStatsRecordValue }
            .filter { $0.type == FollowersStatsType.email.rawValue }
            .compactMap {
                guard
                    let name = $0.name,
                    let subscribedDate = $0.subscribedDate
                    else {
                    return nil
                }
                return StatsFollower(name: name, subscribedDate: subscribedDate as Date, avatarURL: $0.avatarURL)
        }

        self = StatsEmailFollowersInsight(emailFollowersCount: Int(emailCountInsight.count), topEmailFollowers: followers)
    }

    static var recordType: StatsRecordType {
        return .followers
    }


}

extension StatsDotComFollowersInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let countRecordValue = FollowersCountStatsRecordValue(context: context)
        countRecordValue.count = Int64(dotComFollowersCount)
        countRecordValue.type = FollowersStatsType.dotCom.rawValue

        var records: [StatsRecordValue] = topDotComFollowers.map { FollowersStatsRecordValue(context: context, statsFollower: $0, type: .dotCom) }
        records.append(countRecordValue)

        return records
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        let countInsights = statsRecordValues
            .compactMap { $0 as? FollowersCountStatsRecordValue }
            .filter { $0.type == FollowersStatsType.dotCom.rawValue }

        guard let dotComCountInsight = countInsights.first else {
            return nil
        }

        let followers: [StatsFollower] = statsRecordValues
            .compactMap { $0 as? FollowersStatsRecordValue }
            .filter { $0.type == FollowersStatsType.dotCom.rawValue }
            .compactMap {
                guard
                    let name = $0.name,
                    let subscribedDate = $0.subscribedDate
                    else {
                        return nil
                }
                return StatsFollower(name: name, subscribedDate: subscribedDate as Date, avatarURL: $0.avatarURL)
        }

        self = StatsDotComFollowersInsight(dotComFollowersCount: Int(dotComCountInsight.count), topDotComFollowers: followers)
    }

    static var recordType: StatsRecordType {
        return .followers
    }
}
