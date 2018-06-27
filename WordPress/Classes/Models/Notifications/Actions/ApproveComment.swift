import MGSwipeTableCell

final class ApproveComment: DefaultNotificationAction {
    private enum TitleStrings {
        static let approve = NSLocalizedString("Approve", comment: "Approves a Comment")
        static let unapprove = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")
    }

    override var enabled: Bool {
        willSet {
            let newTitle = newValue ? TitleStrings.approve : TitleStrings.unapprove
            setIconTitle(newTitle)
        }
    }

    let approveIcon: UIButton = {
        let title = NSLocalizedString("Approve", comment: "Approves a Comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return approveIcon
    }

    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)? = nil) {
        if enabled {
            unApprove(block: block)
        } else {
            approve(block: block)
        }
    }

    private func unApprove(block: NotificationBlock) {
        setIconTitle(TitleStrings.unapprove)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.unapproveCommentWithBlock(block)
        }
    }

    private func approve(block: NotificationBlock) {
        setIconTitle(TitleStrings.approve)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.approveCommentWithBlock(block)
        }
    }

    private func setIconTitle(_ title: String) {
        icon?.setTitle(title, for: .normal)
    }
}
