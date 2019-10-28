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
