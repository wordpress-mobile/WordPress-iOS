import Foundation
import UIKit
import WordPressFlux

class NoticePresenter: NSObject {
    private let store: NoticeStore
    private var storeReceipt: Receipt?

    private var isPresenting = false

    private init(store: NoticeStore) {
        self.store = store
        super.init()

        storeReceipt = store.onChange { [weak self] in
            self?.presentNextNoticeIfAvailable()
        }
    }

    override convenience init() {
        self.init(store: StoreContainer.shared.notice)
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

        ActionDispatcher.dispatch(NoticeAction.dismiss)
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
