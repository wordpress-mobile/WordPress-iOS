import Foundation
import UIKit
import WordPressFlux

/// NoticePresenter monitors the NoticeStore and is responsible for displaying
/// notices to the user. If the NoticeStore contains multiple notices, each
/// one will be displayed in turn.
///
/// Other than intializing it, you should not need to interact with the
/// NoticePresenter directly.
///
class NoticePresenter: NSObject {
    private let store: NoticeStore
    private var storeReceipt: Receipt?

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
        if let notice = store.nextNotice {
            present(notice)
        }
    }

    private func present(_ notice: Notice) {
        UIApplication.shared.delegate?.window??.rootViewController?.present(alert(from: notice),
                                                                            animated: true,
                                                                            completion: nil)
    }

    private func dismiss() {
        ActionDispatcher.dispatch(NoticeAction.dismiss)
    }

    private func alert(from notice: Notice) -> UIAlertController {
        let alert = UIAlertController(title: notice.title, message: notice.message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: { _ in
            self.dismiss()
        }))

        if let actionTitle = notice.actionTitle,
            let actionHandler = notice.actionHandler {
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                self.dismiss()
                actionHandler()
            }))
        }

        return alert
    }
}
