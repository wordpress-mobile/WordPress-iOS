import MGSwipeTableCell

final class ApproveComment: DefaultNotificationAction {
    let approveIcon: UIButton = {
        let title = NSLocalizedString("Approve", comment: "Approves a Comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return approveIcon
    }

    func execute() {

    }
}
