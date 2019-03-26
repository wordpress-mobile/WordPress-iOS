import XCTest
import CoreData
@testable import WordPress

// A thin wrapper round XCTestCase for Stats test to avoid repeating boilerplate.
class StatsTestCase: XCTestCase {

    fileprivate var manager: TestContextManager!

    override func setUp() {
        manager = TestContextManager()
    }

    var mainContext: NSManagedObjectContext {
        return manager.mainContext
    }

    override func tearDown() {
        mainContext.reset()
    }

    @discardableResult func createStatsRecord(in context: NSManagedObjectContext,
                                              type: StatsRecordType,
                                              period: StatsRecordPeriodType = .notApplicable,
                                              date: Date) -> StatsRecord {
        let newRecord = StatsRecord(context: context)
        newRecord.type = type.rawValue
        newRecord.date = Calendar.autoupdatingCurrent.startOfDay(for: date) as NSDate
        newRecord.period = period.rawValue
        newRecord.blog = defaultBlog

        return newRecord
    }

    lazy var defaultBlog: Blog = {
        return ModelTestHelper.insertDotComBlog(context: mainContext)
    }()


}
