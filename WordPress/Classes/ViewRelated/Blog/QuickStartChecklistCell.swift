import Gridicons
import UIKit

class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .headline)
        }
    }
    @IBOutlet private var descriptionLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(descriptionLabel, textStyle: .subheadline)
        }
    }
    @IBOutlet private var iconView: UIImageView?
    @IBOutlet private var stroke: UIView? {
        didSet {
            stroke?.backgroundColor = .divider
        }
    }
    @IBOutlet private var topSeparator: UIView? {
        didSet {
            topSeparator?.backgroundColor = .divider
        }
    }

    private var bottomStrokeLeading: NSLayoutConstraint?
    private var contentViewLeadingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? contentView.leadingAnchor : contentView.readableContentGuide.leadingAnchor
    }
    private var contentViewTrailingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? contentView.trailingAnchor : contentView.readableContentGuide.trailingAnchor
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .listForeground
        setupConstraints()
    }

    func configure(tour: QuickStartTour, completed: Bool, topSeparatorIsHidden: Bool, lastRow: Bool) {
        setupColors(completed: completed)
        setupTitle(tour: tour, completed: completed)
        setupContent(tour: tour)
        setupAccessibility(tour: tour, completed: completed)
        setupSeperators(topSeparatorIsHidden: topSeparatorIsHidden, lastRow: lastRow)
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}

private extension QuickStartChecklistCell {
    func setupConstraints() {
        guard let stroke = stroke,
            let topSeparator = topSeparator else {
            return
        }

        bottomStrokeLeading = stroke.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        bottomStrokeLeading?.isActive = true
        let strokeSuperviewLeading = stroke.leadingAnchor.constraint(equalTo: contentViewLeadingAnchor)
        strokeSuperviewLeading.priority = UILayoutPriority(999.0)
        strokeSuperviewLeading.isActive = true
        stroke.trailingAnchor.constraint(equalTo: contentViewTrailingAnchor).isActive = true
        topSeparator.leadingAnchor.constraint(equalTo: contentViewLeadingAnchor).isActive = true
        topSeparator.trailingAnchor.constraint(equalTo: contentViewTrailingAnchor).isActive = true
    }

    func setupTitle(tour: QuickStartTour, completed: Bool) {
        let strikeThroughStyle = completed ? 1 : 0
        let titleColor: UIColor = completed ? .neutral(.shade30) : .text
        titleLabel.attributedText = NSAttributedString(string: tour.title,
                                                       attributes: [.strikethroughStyle: strikeThroughStyle,
                                                                    .foregroundColor: titleColor])
    }

    func setupAccessibility(tour: QuickStartTour, completed: Bool) {
        if completed {
            // Overrides the existing accessibility hint in the tour property observer,
            // because users don't need the hint repeated to them after a task is completed.
            accessibilityHint = nil
            accessibilityLabel = tour.titleMarkedCompleted
        } else {
            let hint = tour.accessibilityHintText
            if !hint.isEmpty {
                accessibilityHint = hint
            }
        }
    }

    func setupColors(completed: Bool) {
        if completed {
            descriptionLabel.textColor = .neutral(.shade30)
            iconView?.tintColor = .neutral(.shade30)
        } else {
            descriptionLabel.textColor = .textSubtle
            iconView?.tintColor = .listIcon
        }
    }

    func setupContent(tour: QuickStartTour) {
        descriptionLabel.text = tour.description
        iconView?.image = tour.icon.withRenderingMode(.alwaysTemplate)
    }

    func setupSeperators(topSeparatorIsHidden: Bool, lastRow: Bool) {
        bottomStrokeLeading?.isActive = !lastRow
        topSeparator?.isHidden = topSeparatorIsHidden
    }
}
