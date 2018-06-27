import MGSwipeTableCell

final class EditComment: DefaultNotificationAction {
    let editIcon: UIButton = {
        let title = NSLocalizedString("Edit", comment: "Edits a Comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return editIcon
    }

    func execute(context: ActionContext) {

    }
}
