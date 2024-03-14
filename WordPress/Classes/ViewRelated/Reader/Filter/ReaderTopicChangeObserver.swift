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
        // Skip if `Topic` is not included in the notification payload.
        guard let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
              updated.firstIndex(where: { $0 is Topic }) != nil else {
            return
        }

        Task { @MainActor [weak self] in
            self?.delegate?.readerTopicDidChange()
        }
    }
}
