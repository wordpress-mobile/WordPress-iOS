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

    let interest: RemoteReaderInterest

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
    weak var delegate: ReaderInterestsDataDelegate?

    private(set) var count: Int = 0

    private var interests: [ReaderInterestViewModel] = [] {
        didSet {
            count = interests.count

            delegate?.readerInterestsDidUpdate(self)
        }
    }

    var selectedInterests: [ReaderInterestViewModel] {
        return interests.filter { $0.isSelected }
    }

    private var interestsService: ReaderInterestsService
    private let topics: [ReaderTagTopic]

    /// Creates a new instance of the data source
    /// - Parameter topicService: An Optional `ReaderTopicService` to use. If this is `nil` one will be created on the main context
    init(topics: [ReaderTagTopic], service: ReaderInterestsService? = nil) {
        self.topics = topics

        guard let service = service else {
            let context = ContextManager.sharedInstance().mainContext
            self.interestsService = ReaderTopicService(managedObjectContext: context)
            return
        }

        self.interestsService = service
    }

    /// Fetches the interests from the topic service
    public func reload() {
        interestsService.fetchInterests(success: { [weak self] interests in
            guard let self = self else {
                return
            }

            self.interests = interests
                .filter { interest in
                    // Filter out interests that are already being followed
                    !self.topics.contains(where: { followedTopic in

                        // NOTE: Comparing the topic's title against the interest's slug is a workaround for
                        // topics that contain multiple words.
                        //
                        // We need this workaround because of an unfortunate bug:
                        // When we sync the remotely fetched topic with the locally stored topic, the
                        // "display_name" value is mapped to the local topic's title instead of the "title" value.
                        //
                        // See: ReaderTopicServiceRemote.m, normalizeTopicDictionary:subscribed:recommended:

                        followedTopic.title.caseInsensitiveCompare(interest.slug) == .orderedSame
                    })
                }
                .map { ReaderInterestViewModel(interest: $0) }

        }) { [weak self] (error: Error) in
            DDLogError("Error: Could not retrieve reader interests: \(String(describing: error))")

            self?.interests = []
        }
    }

    /// Reset all selected interests
    public func reset() {
        interests.forEach { $0.isSelected = false }
    }

    /// Returns a reader interest for the specified row
    /// - Parameter row: The index of the item you want to return
    /// - Returns: A reader interest model
    public func interest(for row: Int) -> ReaderInterestViewModel {
        return interests[row]
    }
}
