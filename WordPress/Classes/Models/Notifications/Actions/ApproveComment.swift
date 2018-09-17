import MGSwipeTableCell

/// Encapsulates logic to approve a cooment
class ApproveComment: DefaultNotificationActionCommand, AccessibleFormattableContentActionCommand {
    enum TitleStrings {
        static let approve = NSLocalizedString("Approve", comment: "Approves a Comment")
        static let unapprove = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")
        static let selected = NSLocalizedString("Approved", comment: "Unapprove a comment")
    }

    enum TitleHints {
        static let approve = NSLocalizedString("Approves the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to approve a comment")
        static let unapprove = NSLocalizedString("Unapproves the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unapprove a comment")
        static let selected = NSLocalizedString("Unapproves the comment", comment: "Unapproves a comment. Spoken Hint.")
    }

    override var on: Bool {
        willSet {
            let newTitle = newValue ? TitleStrings.unapprove : TitleStrings.approve
            let newHint = newValue ? TitleHints.unapprove : TitleHints.approve

            setIconStrings(title: newTitle, label: newTitle, hint: newHint)

            updateVisualState()
        }
    }

    let approveIcon: UIButton = {
        let title = TitleStrings.approve
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = TitleHints.approve
        return button
    }()

    override var icon: UIButton? {
        return approveIcon
    }

    override func execute<ObjectType: FormattableCommentContent>(context: ActionContext<ObjectType>) {
        let block = context.block
        if on {
            unApprove(block: block)
        } else {
            approve(block: block)
        }
    }

    private func unApprove(block: FormattableCommentContent) {
        setIconStrings(title: TitleStrings.unapprove,
                       label: TitleStrings.unapprove,
                       hint: TitleHints.unapprove)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.unapproveCommentWithBlock(block, completion: { [weak self] success in
                if success {
                    self?.switchOnState()
                }
            })
        }
    }

    private func approve(block: FormattableCommentContent) {
        setIconStrings(title: TitleStrings.approve,
                       label: TitleStrings.approve,
                       hint: TitleHints.approve)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.approveCommentWithBlock(block, completion: { [weak self] success in
                if success {
                    self?.switchOnState()
                }
            })
        }
    }

    private func switchOnState() {
        on = !on
        updateVisualState()
    }

    private func updateVisualState() {
        guard let button = icon as? MGSwipeButton else {
            return
        }

        let newBackgroundColor = on ? WPStyleGuide.grey() : WPStyleGuide.wordPressBlue()
        button.backgroundColor = newBackgroundColor

        resetDefaultPadding()
    }

    private func resetDefaultPadding() {
        guard let button = icon as? MGSwipeButton else {
            return
        }

        let buttonDefaultPadding: CGFloat = 10
        button.setPadding(buttonDefaultPadding)
    }
}
