import Foundation
import CoreData


public class TopViewedAuthorStatsRecordValue: StatsRecordValue {

    public var avatarURL: URL? {
        guard let url = avatarURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}
