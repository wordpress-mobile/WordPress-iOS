import Foundation

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
        coordinator = ReaderTopicCollectionViewCoordinator(collectionView: self, topics: topics)
        coordinator?.delegate = self
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
