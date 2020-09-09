/// Encapsulates logic to approve a login attempt
class ApproveLogin: DefaultNotificationActionCommand {
    enum TitleStrings {
        static let approve = NSLocalizedString("Approve", comment: "Approves a Login Attempt")
        static let unapprove = NSLocalizedString("Unapprove", comment: "Unapproves a Login Attempt")
    }

    enum TitleHints {
        static let approve = NSLocalizedString("Approves the Login Attempt.", comment: "VoiceOver accessibility hint, informing the user the button can be used to approve a login attempt")
        static let unapprove = NSLocalizedString("Unapproves the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unapprove a login attempt")
    }

    override var actionTitle: String {
        return on ? TitleStrings.unapprove : TitleStrings.approve
    }

    override var actionColor: UIColor {
        return on ? .neutral(.shade30) : .primary
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
