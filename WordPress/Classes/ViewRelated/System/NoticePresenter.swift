import Foundation
import UIKit
import WordPressFlux

class NoticePresenter {
    static let shared = NoticePresenter()

    private let store: NoticeStore
    private var storeReceipt: Receipt?

    private var isPresenting = false

    private init(store: NoticeStore = StoreContainer.shared.notice) {
        self.store = store

        storeReceipt = store.onChange { [weak self] in
            self?.presentNextNoticeIfAvailable()
        }
    }

    private func presentNextNoticeIfAvailable() {
        if !isPresenting {
            if let notice = store.nextNotice {
                present(notice)
            }
        }
    }

    private func present(_ notice: Notice) {
        isPresenting = true

        UIApplication.shared.delegate?.window??.rootViewController?.present(alert(from: notice),
                                                                            animated: true,
                                                                            completion: nil)
    }

    private func dismiss(_ notice: Notice) {
        isPresenting = false

        ActionDispatcher.dispatch(NoticeAction.dismiss(notice))
    }

    private func alert(from notice: Notice) -> UIAlertController {
        let alert = UIAlertController(title: notice.title, message: notice.message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: { _ in
            self.dismiss(notice)
        }))

        if let actionTitle = notice.actionTitle,
            let actionHandler = notice.actionHandler {
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                self.dismiss(notice)
                actionHandler()
            }))
        }

        return alert
    }
}
