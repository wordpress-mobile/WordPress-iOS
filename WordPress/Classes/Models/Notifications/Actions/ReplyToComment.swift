import MGSwipeTableCell

final class ReplyToComment: DefaultNotificationAction {
    let replyIcon: UIButton = {
        let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return replyIcon
    }

    func execute(context: ActionContext) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        let block = context.block
        let content = context.content
        actionsService?.replyCommentWithBlock(block, content: content, completion: { success in
            guard success else {
                generator.notificationOccurred(.error)
                //self.displayReplyErrorWithBlock(block, content: content)
                return
            }

            context.completion?()
        })

//        ReachabilityUtils.onAvailableInternetConnectionDo {
//            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] requestCompletion in
//                self?.actionsService?.replyCommentWithBlock(block, completion: { success in
//                    requestCompletion(success)
//                })
//            })
//
//            onCompletion?(request)
//        }
    }
}
