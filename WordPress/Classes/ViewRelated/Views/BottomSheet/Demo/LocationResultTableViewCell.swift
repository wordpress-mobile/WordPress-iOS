
import UIKit

// MARK: - LocationResultTableViewCell

class LocationResultTableViewCell: UITableViewCell {

    /// The designated cell reuse identifier
    static var reuseIdentifier: String { return "\(self)" }

    // MARK: UITableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: LocationResultTableViewCell.reuseIdentifier)
        initialize()
    }

    required init?(coder aDecorder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initialize()
    }

    // MARK: Internal behavior

    func setKey(_ key: String) {
        textLabel?.text = key
    }

    func setValue(_ value: String) {
        detailTextLabel?.text = value
    }
}

// MARK: Private behavior

private extension LocationResultTableViewCell {
    func initialize() {
        tintColor = WPStyleGuide.mediumBlue()

        selectionStyle = .none
        accessoryType = .none

        textLabel?.textColor = WPStyleGuide.darkGrey()
        detailTextLabel?.textColor = WPStyleGuide.grey()
    }
}
