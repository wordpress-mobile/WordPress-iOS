import Foundation

/// A drop in collection view that will configure the collection view to display the topics chip group:
/// - Overrides the layout to be `ReaderInterestsCollectionViewFlowLayout`
/// - Creates the ReaderTopicCollectionViewCoordinator
/// - Uses the dynamic height collection view class to automatically change its size to the content
///
/// When implementing you can also use the `topicDelegate` to know when the group is expanded/collapsed, or if a topic chip was selected
class TopicsCollectionView: DynamicHeightCollectionView {
    var coordinator: ReaderTopicCollectionViewCoordinator?

    weak var topicDelegate: ReaderTopicCollectionViewCoordinatorDelegate?

    var topics: [String] = [] {
        didSet {
            coordinator?.topics = topics
        }
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        collectionViewLayout = ReaderInterestsCollectionViewFlowLayout()

        coordinator = ReaderTopicCollectionViewCoordinator(collectionView: self, topics: topics)
        coordinator?.delegate = self
    }

    func collapse() {
        coordinator?.changeState(.collapsed)
    }

    override func accessibilityElementCount() -> Int {
        guard let dataSource else {
            return 0
        }

        return dataSource.collectionView(self, numberOfItemsInSection: 0)
    }
}

extension TopicsCollectionView: ReaderTopicCollectionViewCoordinatorDelegate {
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didSelectTopic topic: String) {
        topicDelegate?.coordinator(coordinator, didSelectTopic: topic)
    }

    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didChangeState: ReaderTopicCollectionViewState) {
        topicDelegate?.coordinator(coordinator, didChangeState: didChangeState)
    }
}
