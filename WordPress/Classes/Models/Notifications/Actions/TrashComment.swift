import MGSwipeTableCell

final class TrashComment: DefaultNotificationAction {
    let trashIcon: UIButton = {
        let title = NSLocalizedString("Trash", comment: "Trashes a comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return trashIcon
    }

    func execute() {

    }
}
