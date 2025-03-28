import UIKit
import WordPressShared
import WordPressUI

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
        textLabel?.textColor = UIAppColor.neutral(.shade20)
        detailTextLabel?.textColor = UIAppColor.neutral(.shade20)
    }
}
