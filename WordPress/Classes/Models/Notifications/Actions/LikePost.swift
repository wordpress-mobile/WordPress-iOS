import MGSwipeTableCell

final class LikePost: DefaultNotificationActionCommand {
    let likeIcon: UIButton = {
        let title = NSLocalizedString("Like", comment: "Like a post.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return likeIcon
    }

    override func execute(context: ActionContext) {

    }
}
