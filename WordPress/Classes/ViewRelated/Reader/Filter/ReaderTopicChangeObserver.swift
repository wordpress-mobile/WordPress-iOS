import CoreData

// MARK: - Protocols

protocol ReaderTopicObserverDelegate: NSObjectProtocol {
    func readerTopicDidChange()
}

protocol ReaderTopicObserving: NSObjectProtocol {
    var delegate: ReaderTopicObserverDelegate? { get set }
}

// MARK: - Concrete Class

/// Observes model changes to `Topic` and notifies the delegate.
/// The type `Topic` is restricted to `ReaderAbstractTopic` and its subclasses.
///
class ReaderTopicChangeObserver<Topic: ReaderAbstractTopic>: NSObject, ReaderTopicObserving {
    weak var delegate: ReaderTopicObserverDelegate?

    init(delegate: ReaderTopicObserverDelegate? = nil) {
        self.delegate = delegate
        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleObjectsChange),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: nil)
    }

    @objc private func handleObjectsChange(_ notification: Foundation.Notification) {
        // Check for objects with type `Topic` within the Notification.
        let notificationContainsTopic = [notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                                         notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>]
                                     .compactMap { set in set?.firstIndex(where: { $0 is Topic }) }
                                     .count > 0

        // Skip if `Topic` is not included at all in the notification payload.
        guard notificationContainsTopic else {
            return
        }

        Task { @MainActor [weak self] in
            self?.delegate?.readerTopicDidChange()
        }
    }
}
