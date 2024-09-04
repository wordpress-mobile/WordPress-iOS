import WordPressShared

extension UITableViewCell {
    /// Enable cell interaction
    @objc func enable() {
        isUserInteractionEnabled = true
        textLabel?.isEnabled = true
        textLabel?.textColor = .label
        detailTextLabel?.textColor = .systemGray
    }

    /// Disable cell interaction
    @objc func disable() {
        accessoryType = .none
        isUserInteractionEnabled = false
        textLabel?.isEnabled = false
        textLabel?.textColor = AppColor.neutral(.shade20)
        detailTextLabel?.textColor = AppColor.neutral(.shade20)
    }
}
