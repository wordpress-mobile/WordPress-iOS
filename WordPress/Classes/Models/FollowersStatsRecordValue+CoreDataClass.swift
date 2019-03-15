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

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
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

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .followers
    }

}
