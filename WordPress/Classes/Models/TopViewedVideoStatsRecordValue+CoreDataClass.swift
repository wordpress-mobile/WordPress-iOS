import Foundation
import CoreData


public class TopViewedVideoStatsRecordValue: StatsRecordValue {

    public var postURL: URL? {
        guard let url = postURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}
