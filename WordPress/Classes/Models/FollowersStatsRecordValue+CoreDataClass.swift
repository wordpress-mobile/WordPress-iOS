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
        guard let emailCountInsight = countInsight(followerType: .email, from: statsRecordValues) else {
            return nil
        }

        let followers: [StatsFollower] = statsFollowers(followerType: .email, from: statsRecordValues).compactMap { StatsFollower(recordValue: $0) }

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
        guard let dotComCountInsight = countInsight(followerType: .dotCom, from: statsRecordValues) else {
            return nil
        }

        let followers = statsFollowers(followerType: .dotCom, from: statsRecordValues).compactMap { StatsFollower(recordValue: $0) }

        self = StatsDotComFollowersInsight(dotComFollowersCount: Int(dotComCountInsight.count), topDotComFollowers: followers)
    }

    static var recordType: StatsRecordType {
        return .followers
    }
}

fileprivate func countInsight(followerType: FollowersStatsType, from recordValues: [StatsRecordValue]) -> FollowersCountStatsRecordValue? {
    return recordValues
        .compactMap { $0 as? FollowersCountStatsRecordValue }
        .filter { $0.type == followerType.rawValue }
        .first
}

fileprivate func statsFollowers(followerType: FollowersStatsType, from recordValues: [StatsRecordValue]) -> [FollowersStatsRecordValue] {
    return recordValues
        .compactMap { $0 as? FollowersStatsRecordValue }
        .filter { $0.type == followerType.rawValue }
}

fileprivate extension StatsFollower {
    init?(recordValue: FollowersStatsRecordValue) {
        guard
            let name = recordValue.name,
            let subscribedDate = recordValue.subscribedDate
            else {
                return nil
        }

        self = StatsFollower(name: name, subscribedDate: subscribedDate as Date, avatarURL: recordValue.avatarURL)
    }
}
