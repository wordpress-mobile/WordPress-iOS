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
        accessoryView = nil
        accessoryType = .none
        refreshIconColor()
        refreshTitleLabel()
    }

    private func refreshTitleLabel() {
        guard let label = titleLabel,
            let text = label.text else {
                return
        }

        if state == .completed {
            label.textColor = .neutral(.shade30)
            label.attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        }
    }
}

private extension QuickStartListTitleCell {
    func refreshIconColor() {
        switch state {
        case .customizeIncomplete:
            circleImageView?.backgroundColor = .primary(.shade40)
        case .growIncomplete:
            circleImageView?.backgroundColor = .accent
        default:
            circleImageView?.backgroundColor = .neutral(.shade30)
        }

        guard let iconImageView = iconImageView,
            let iconImage = iconImageView.image else {
                return
        }

        iconImageView.image = iconImage.imageWithTintColor(.white)
    }
}
