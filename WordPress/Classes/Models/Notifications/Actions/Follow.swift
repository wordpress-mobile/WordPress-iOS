import UIKit
import WordPressUI
import FormattableContentKit

/// Encapsulates logic to follow a blog
final class Follow: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("notifications.action.subscribe.title", value: "Subscribe", comment: "Prompt to subscribe to a blog.")
    static let hint = NSLocalizedString("notifications.action.subscribe.hint", value: "Subscribe to the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to subscribe to a blog.")
    static let selectedTitle = NSLocalizedString("notifications.action.subscribe.selectedTitle", value: "Subscribed", comment: "User is subscribed to the blog.")
    static let selectedHint = NSLocalizedString("notifications.action.subscribe.selectedHint", value: "Unsubscribe from the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unsubscribe from a blog.")

    override var actionTitle: String {
        return Follow.title
    }

    override var actionColor: UIColor {
        return on ? UIAppColor.neutral(.shade30) : UIAppColor.primary
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let _ = context.block as? FormattableUserContent else {
            super.execute(context: context)
            return
        }
    }
}
