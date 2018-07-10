import MGSwipeTableCell

/// Encapsulates logic to approve a cooment
final class ApproveComment: DefaultNotificationActionCommand {
    private enum TitleStrings {
        static let approve = NSLocalizedString("Approve", comment: "Approves a Comment")
        static let unapprove = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")
    }

    override var on: Bool {
        willSet {
            let newTitle = newValue ? TitleStrings.approve : TitleStrings.unapprove
            setIconTitle(newTitle)
        }
    }

    let approveIcon: UIButton = {
        let title = NSLocalizedString("Approve", comment: "Approves a Comment")
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        return button
    }()

    override var icon: UIButton? {
        return approveIcon
    }

    override func execute(context: ActionContext) {
        let block = context.block
        if on {
            unApprove(block: block)
        } else {
            approve(block: block)
        }
    }

    private func unApprove(block: ActionableObject) {
        setIconTitle(TitleStrings.unapprove)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.unapproveCommentWithBlock(block)
        }
    }

    private func approve(block: ActionableObject) {
        setIconTitle(TitleStrings.approve)

        ReachabilityUtils.onAvailableInternetConnectionDo {
            actionsService?.approveCommentWithBlock(block)
        }
    }

    private func setIconTitle(_ title: String) {
        icon?.setTitle(title, for: .normal)
        setAccessibilityLabel(title)
    }

    private func setAccessibilityLabel(_ title: String) {
        icon?.accessibilityLabel = title
    }
}
