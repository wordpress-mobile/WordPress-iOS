import WordPressShared

extension UITableViewCell {
    /// Enable cell interaction
    @objc func enable() {
        isUserInteractionEnabled = true
        textLabel?.isEnabled = true
        textLabel?.textColor = .text
        detailTextLabel?.textColor = .listSmallIcon
    }

    /// Disable cell interaction
    @objc func disable() {
        accessoryType = .none
        isUserInteractionEnabled = false
        textLabel?.isEnabled = false
        textLabel?.textColor = .neutral(.shade20)
        detailTextLabel?.textColor = .neutral(.shade20)
    }
}
