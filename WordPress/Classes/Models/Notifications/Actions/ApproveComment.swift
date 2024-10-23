/// Encapsulates logic to approve a comment
class ApproveComment: DefaultNotificationActionCommand {
    enum TitleStrings {
        static let approve = NSLocalizedString("Approve Comment", comment: "Approves a Comment")
        static let unapprove = NSLocalizedString("Unapprove Comment", comment: "Unapproves a Comment")
    }

    enum TitleHints {
        static let approve = NSLocalizedString("Approves the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to approve a comment")
        static let unapprove = NSLocalizedString("Unapproves the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unapprove a comment")
    }

    override var actionTitle: String {
        return on ? TitleStrings.unapprove : TitleStrings.approve
    }

    override var actionColor: UIColor {
        return on ? UIAppColor.neutral(.shade30) : UIAppColor.primary
    }

    override func execute<ObjectType: FormattableContent>(context: ActionContext<ObjectType>) {
        guard let block = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
        if on {
            unApprove(block: block)
        } else {
            approve(block: block)
        }
    }

    private func unApprove(block: FormattableCommentContent) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.unapproveCommentWithBlock(block, completion: { [weak self] success in
                if success {
                    self?.on.toggle()
                }
            })
        }
    }

    private func approve(block: FormattableCommentContent) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.approveCommentWithBlock(block, completion: { [weak self] success in
                if success {
                    self?.on.toggle()
                }
            })
        }
    }
}
