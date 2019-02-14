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
