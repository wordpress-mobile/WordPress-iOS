import Foundation
import CoreData


public class OtherAndTotalViewsCountStatsRecordValue: StatsRecordValue {

    convenience init(context: NSManagedObjectContext, otherCount: Int, totalCount: Int) {
        self.init(context: context)

        self.otherCount = Int64(otherCount)
        self.totalCount = Int64(totalCount)
    }

}
