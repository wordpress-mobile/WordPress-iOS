import Foundation
import UIKit
import WordPressShared.WPTableViewCell


class WPReusableTableViewCell: WPTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
        textLabel?.textAlignment = .Left
        textLabel?.adjustsFontSizeToFitWidth = false
        detailTextLabel?.text = nil
        detailTextLabel?.textColor = UIColor.blackColor()
        imageView?.image = nil
        accessoryType = .None
        accessoryView = nil
        selectionStyle = .Default
        accessibilityLabel = nil
    }
}

class WPTableViewCellDefault: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellSubtitle: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellValue1: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellValue2: WPReusableTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value2, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellBadge: WPTableViewCellDefault {
    var badgeCount: Int = 0 {
        didSet {
            if badgeCount > 0 {
                badgeLabel.text = String(badgeCount)
                accessoryView = badgeLabel
                accessoryType = .None
            } else {
                accessoryView = nil
                accessoryType = .DisclosureIndicator
            }
        }
    }

    private lazy var badgeLabel: UILabel = {
        let label = UILabel(frame: CGRect(origin: CGPointZero, size: WPTableViewCellBadge.badgeSize))
        label.layer.masksToBounds = true
        label.layer.cornerRadius = WPTableViewCellBadge.badgeCornerRadius
        label.textAlignment = .Center
        label.backgroundColor = WPStyleGuide.newKidOnTheBlockBlue()
        label.textColor = UIColor.whiteColor()
        return label
    }()

    private static let badgeSize = CGSize(width: 50, height: 30)
    private static var badgeCornerRadius: CGFloat {
        return badgeSize.height / 2
    }
}
