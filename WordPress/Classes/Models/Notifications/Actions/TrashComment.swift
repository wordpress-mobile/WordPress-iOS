import MGSwipeTableCell

final class TrashComment: DefaultNotificationAction {
    let trashIcon: UIButton = {
        let title = NSLocalizedString("Trash", comment: "Trashes a comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed())
//        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed(), callback: { [weak self] _ in
//            ReachabilityUtils.onAvailableInternetConnectionDo {
//                let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] onCompletion in
//                    self?.actionsService.deleteCommentWithBlock(block) { success in
//                        onCompletion(success)
//                    }
//                })
//
//                self?.showUndeleteForNoteWithID(note.objectID, request: request)
//            }
//            return true
//        })
//
//        return button
//        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed(), callback: { [weak self] _ in
//            ReachabilityUtils.onAvailableInternetConnectionDo {
//                let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] onCompletion in
//                    self?.actionsService.deleteCommentWithBlock(block) { success in
//                        onCompletion(success)
//                    }
//                })
//
//                self?.showUndeleteForNoteWithID(note.objectID, request: request)
//            }
//        })
//        return button
    }()

    override var icon: UIButton? {
        return trashIcon
    }

    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)?) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] requestCompletion in
                self?.actionsService?.deleteCommentWithBlock(block, completion: { success in
                    requestCompletion(success)
                })
            })

            onCompletion?(request)
        }
    }

//    func execute(block: NotificationBlock, compl) {
//        ReachabilityUtils.onAvailableInternetConnectionDo {
//            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] onCompletion in
//                self?.actionsService.deleteCommentWithBlock(block) { success in
//                    onCompletion(success)
//                }
//            })
//
//            self?.showUndeleteForNoteWithID(note.objectID, request: request)
//        }
//    }
}
