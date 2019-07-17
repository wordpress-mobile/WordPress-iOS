import Foundation
import UIKit
import WordPressShared
import WordPressUI
import Gridicons

class WPReusableTableViewCell: WPTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
        textLabel?.textAlignment = .natural
        textLabel?.adjustsFontSizeToFitWidth = false
        detailTextLabel?.text = nil
        detailTextLabel?.textColor = UIColor.black
        imageView?.image = nil
        accessoryType = .none
        accessoryView = nil
        selectionStyle = .default
        accessibilityLabel = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    fileprivate func commonInit() {
        setupLabel(textLabel)
        setupLabel(detailTextLabel)
    }

    private func setupLabel(_ label: UILabel?) {
        label?.numberOfLines = 0
        label?.adjustsFontForContentSizeCategory = true
    }
}

class WPTableViewCellDefault: WPReusableTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellSubtitle: WPReusableTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellValue1: WPReusableTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func commonInit() {
        super.commonInit()
        detailTextLabel?.numberOfLines = 1
    }
}

class WPTableViewCellValue2: WPReusableTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value2, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class WPTableViewCellBadge: WPTableViewCellDefault {
    @objc var badgeCount: Int = 0 {
        didSet {
            if badgeCount > 0 {
                badgeLabel.text = String(badgeCount)
                accessoryView = badgeLabel
                accessoryType = .none
            } else {
                accessoryView = nil
            }
        }
    }

    fileprivate lazy var badgeLabel: UILabel = {
        let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: WPTableViewCellBadge.badgeSize))
        label.layer.masksToBounds = true
        label.layer.cornerRadius = WPTableViewCellBadge.badgeCornerRadius
        label.textAlignment = .center
        label.backgroundColor = WPStyleGuide.newKidOnTheBlockBlue()
        label.textColor = UIColor.white
        return label
    }()

    fileprivate static let badgeSize = CGSize(width: 50, height: 30)
    fileprivate static var badgeCornerRadius: CGFloat {
        return badgeSize.height / 2
    }
}

class WPTableViewCellIndicator: WPTableViewCellDefault {
    var showIndicator: Bool = false {
        didSet {
            if showIndicator {
                accessoryView = indicatorView
                accessoryType = .none
            } else {
                accessoryView = nil
            }
        }
    }

    fileprivate lazy var indicatorView: UIView = {
        let view = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10)))
        view.layer.masksToBounds = true
        view.layer.cornerRadius =  view.frame.height / 2
        view.backgroundColor = .accent
        return view
    }()
}
