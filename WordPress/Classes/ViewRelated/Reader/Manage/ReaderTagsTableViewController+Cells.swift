import UIKit
import Gridicons
import WordPressUI

extension ReaderTagsTableViewModel {
    func configure(cell: UITableViewCell, for topic: ReaderTagTopic?) {
        guard let topic else {
            configureAddTag(cell: cell)
            return
        }

        cell.textLabel?.text = topic.title

        let button = UIButton.closeAccessoryButton()
        button.addTarget(self, action: #selector(tappedAccessory(_:)), for: .touchUpInside)
        let unfollowString = NSLocalizedString(
            "reader.tags.unfollow.accessibility.label",
            value: "Unfollow %@",
            comment: "Accessibility label for unsubscribing from a tag"
        )
        button.accessibilityLabel = String(format: unfollowString, topic.title)
        cell.accessoryView = button
        cell.accessibilityElements = [button]
    }

    private func configureAddTag(cell: UITableViewCell) {
        cell.textLabel?.text = NSLocalizedString(
            "reader.tags.add.tag",
            value: "Add a Tag",
            comment: "Title of a feature to add a new tag to the tags subscribed by the user."
        )
        cell.accessoryView = UIImageView(image: UIImage.gridicon(.plusSmall))
    }
}

// MARK: - Close Accessory Button
private extension UIButton {

    enum Constants {
        static let size = CGSize(width: 40, height: 40)
        static let image = UIImage.gridicon(.crossSmall)
        static let tintColor = UIAppColor.gray(.shade10)
        static let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8) // To better align with the plus sign accessory view
    }

    static func closeAccessoryButton() -> UIButton {
        let button = UIButton(frame: CGRect(origin: .zero, size: Constants.size))
        button.setImage(Constants.image, for: .normal)
        button.imageEdgeInsets = Constants.insets
        button.imageView?.tintColor = Constants.tintColor
        return button
    }
}
