import Foundation
import UIKit
import WordPressFlux

class InAppNotificationPresenter {
    static let shared = InAppNotificationPresenter()

    private let store: InAppNotificationStore
    private var storeReceipt: Receipt?

    private var isPresenting = false

    private init(store: InAppNotificationStore = StoreContainer.shared.notification) {
        self.store = store

        storeReceipt = store.onChange { [weak self] in
            self?.presentNextNotificationIfAvailable()
        }
    }

    private func presentNextNotificationIfAvailable() {
        if !isPresenting {
            if let notification = store.nextNotification {
                present(notification)
            }
        }
    }

    private func present(_ notification: InAppNotification) {
        isPresenting = true

        UIApplication.shared.delegate?.window??.rootViewController?.present(alert(from: notification),
                                                                            animated: true,
                                                                            completion: nil)
    }

    private func dismiss(_ notification: InAppNotification) {
        isPresenting = false

        ActionDispatcher.dispatch(InAppNotificationAction.dismiss(notification))
    }

    private func alert(from notification: InAppNotification) -> UIAlertController {
        let alert = UIAlertController(title: notification.title, message: notification.message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: { _ in
            self.dismiss(notification)
        }))

        if let actionTitle = notification.actionTitle,
            let actionHandler = notification.actionHandler {
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                self.dismiss(notification)
                actionHandler()
            }))
        }

        return alert
    }
}

