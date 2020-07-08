import Foundation

// MARK: - ReaderInterestViewModel
class ReaderInterestViewModel {
    var isSelected: Bool = false

    var title: String {
        return interest.title
    }

    var slug: String {
        return interest.slug
    }

    private var interest: RemoteReaderInterest

    init(interest: RemoteReaderInterest) {
        self.interest = interest
    }

    public func toggleSelected() {
        self.isSelected = !isSelected
    }
}

// MARK: - ReaderInterestsDataDelegate
protocol ReaderInterestsDataDelegate: AnyObject {
    func readerInterestsDidUpdate(_ dataSource: ReaderInterestsDataSource)
}

// MARK: - ReaderInterestsDataSource
class ReaderInterestsDataSource {
    var delegate: ReaderInterestsDataDelegate?

    private(set) var count: Int = 0
    private(set) var interests: [ReaderInterestViewModel] = [] {
        didSet {
            count = interests.count

            delegate?.readerInterestsDidUpdate(self)
        }
    }

    private var topicService: ReaderTopicService

    init(topicService: ReaderTopicService? = nil) {
        guard let topicService = topicService else {
            let context = ContextManager.sharedInstance().mainContext
            self.topicService = ReaderTopicService(managedObjectContext: context)

            return
        }

        self.topicService = topicService
    }

    public func reload() {
        topicService.fetchInterests(success: { interests in
            self.interests = interests.map({ ReaderInterestViewModel(interest: $0)})
        }) { (error: Error) in
            DDLogError("Error: Could not retrieve reader interests: \(String(describing: error))")

            self.interests = []
        }
    }

    public func toggleSelected(for row: Int) {
        interests[row].toggleSelected()
    }

    public func interest(for row: Int) -> ReaderInterestViewModel {
        return interests[row]
    }
}
