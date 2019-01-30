@objc
class QuickStartListTitleCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel?
    @IBOutlet private var countLabel: UILabel?
    @IBOutlet private var circleImageView: CircularImageView?
    @IBOutlet private var iconImageView: UIImageView?
    @objc var state: QuickStartTitleState = .undefined {
        didSet {
            refreshIconColor()
        }
    }

    @objc static let reuseIdentifier = "QuickStartListTitleCell"

    override var textLabel: UILabel? {
        return titleLabel
    }

    override var detailTextLabel: UILabel? {
        return countLabel
    }

    override var imageView: UIImageView? {
        return iconImageView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshIconColor()
    }

    private func refreshIconColor() {
        switch state {
        case .customizeIncomplete:
            circleImageView?.backgroundColor = .mediumBlue
        case .growIncomplete:
            circleImageView?.backgroundColor = .mediumPink
        default:
            circleImageView?.backgroundColor = .wpGrey
        }

        guard let iconImageView = iconImageView,
            let iconImage = iconImageView.image else {
            return
        }

        iconImageView.image = iconImage.imageWithTintColor(.white)
    }
}

private extension UIColor {
    class var mediumBlue: UIColor {
        return WPStyleGuide.mediumBlue()
    }

    class var mediumPink: UIColor {
        return UIColor(red: 188/255, green: 70/255, blue: 129/255, alpha: 1.0)
    }

    class var wpGrey: UIColor {
        return WPStyleGuide.grey()
    }
}
