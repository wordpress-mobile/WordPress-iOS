import MGSwipeTableCell

final class LikePost: DefaultNotificationAction {
    let likeIcon: UIButton = {
        let title = NSLocalizedString("Like", comment: "Like a post.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return likeIcon
    }

    func execute(context: ActionContext) {

    }
}
