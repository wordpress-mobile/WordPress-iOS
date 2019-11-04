final class StatsPeriodAsyncOperation<TimeStatsType: StatsTimeIntervalData>: AsyncOperation {
    typealias StatsPeriodCompletion = (TimeStatsType?, Error?) -> Void

    private weak var service: StatsServiceRemoteV2?
    private let period: StatsPeriodUnit
    private let date: Date
    private let limit: Int
    private var completion: StatsPeriodCompletion

    init(service: StatsServiceRemoteV2, for period: StatsPeriodUnit, date: Date, limit: Int = 10, completion: @escaping StatsPeriodCompletion) {
        self.service = service
        self.period = period
        self.date = date
        self.limit = limit
        self.completion = completion
    }

    override func main() {
        service?.getData(for: period, endingOn: date, limit: limit) { [unowned self] (type: TimeStatsType?, error: Error?) in
            if self.isCancelled {
                self.state = .isFinished
                return
            }

            self.completion(type, error)
        }
    }
}

final class StatsPublishedPostsAsyncOperation: AsyncOperation {
    typealias StatsPeriodCompletion = (StatsPublishedPostsTimeIntervalData?, Error?) -> Void

    private weak var service: StatsServiceRemoteV2?
    private let period: StatsPeriodUnit
    private let date: Date
    private let limit: Int
    private var completion: StatsPeriodCompletion

    init(service: StatsServiceRemoteV2, for period: StatsPeriodUnit, date: Date, limit: Int = 10, completion: @escaping StatsPeriodCompletion) {
        self.service = service
        self.period = period
        self.date = date
        self.limit = limit
        self.completion = completion
    }

    override func main() {
        service?.getData(for: period, endingOn: date, limit: limit) { [unowned self] (published: StatsPublishedPostsTimeIntervalData?, error: Error?) in
            if self.isCancelled {
                self.state = .isFinished
                return
            }

            self.completion(published, error)
        }
    }
}

final class StatsPostDetailAsyncOperation: AsyncOperation {
    typealias StatsPeriodCompletion = (StatsPostDetails?, Error?) -> Void

    private weak var service: StatsServiceRemoteV2?
    private let postId: Int
    private var completion: StatsPeriodCompletion

    init(service: StatsServiceRemoteV2, for postId: Int, completion: @escaping StatsPeriodCompletion) {
        self.service = service
        self.postId = postId
        self.completion = completion
    }

    override func main() {
        service?.getDetails(forPostID: postId) { [unowned self] (details: StatsPostDetails?, error: Error?) in
            if self.isCancelled {
                self.state = .isFinished
                return
            }

            self.completion(details, error)
        }
    }
}
