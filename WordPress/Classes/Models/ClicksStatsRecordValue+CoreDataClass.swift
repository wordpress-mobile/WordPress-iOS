import Foundation
import CoreData


public class ClicksStatsRecordValue: StatsRecordValue {

    public var clickedURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

}
