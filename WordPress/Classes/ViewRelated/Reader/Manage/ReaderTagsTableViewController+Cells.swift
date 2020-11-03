extension ReaderTagsTableViewModel {
    func configure(cell: UITableViewCell, for topic: ReaderTagTopic?) {
        guard let topic = topic else {
            configureAddTag(cell: cell)
            return
        }

        cell.textLabel?.text = topic.title

        let button = UIButton.closeAccessoryButton()
        button.addTarget(self, action: #selector(tappedAccessory(_:)), for: .touchUpInside)
        let unfollowString = NSLocalizedString("Unfollow %@", comment: "Accessibility label for unfollowing a tag")
        button.accessibilityLabel = String(format: unfollowString, topic.title)
        cell.accessoryView = button
        cell.accessibilityElements = [button]
    }

    private func configureAddTag(cell: UITableViewCell) {
        cell.textLabel?.text = NSLocalizedString("Add a Topic", comment: "Title of a feature to add a new topic to the topics subscribed by the user.")
        cell.accessoryView = UIImageView(image: UIImage.gridicon(.plusSmall))
    }
}

// MARK: - Close Accessory Button
private extension UIButton {

    enum Constants {
        static let size = CGSize(width: 40, height: 40)
        static let image = UIImage.gridicon(.crossSmall)
        static let tintColor = MurielColor(name: .gray, shade: .shade10)
        static let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8) // To better align with the plus sign accessory view
    }

    static func closeAccessoryButton() -> UIButton {
        let button = UIButton(frame: CGRect(origin: .zero, size: Constants.size))
        button.setImage(Constants.image, for: .normal)
        button.imageEdgeInsets = Constants.insets
        button.imageView?.tintColor = UIColor.muriel(color: Constants.tintColor)
        return button
    }
}
