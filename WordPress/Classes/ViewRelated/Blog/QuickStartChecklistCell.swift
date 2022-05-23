import Gridicons
import UIKit

class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .callout, fontWeight: .semibold)
        }
    }
    @IBOutlet private var descriptionLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(descriptionLabel, textStyle: .footnote)
        }
    }
    @IBOutlet private weak var descriptionContainerView: UIStackView!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var iconContainerView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var checkmarkContainerView: UIStackView!
    @IBOutlet private weak var checkmarkImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(tour: QuickStartTour, completed: Bool) {
        setupColors(tour: tour, completed: completed)
        setupTitle(tour: tour, completed: completed)
        setupContent(tour: tour)
        setupCheckmarkView(completed: completed)
        setupAccessibility(tour: tour, completed: completed)
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}

private extension QuickStartChecklistCell {

    func applyStyles() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        mainContainerView.layer.cornerRadius = Constants.mainContainerCornerRadius
        iconContainerView.layer.cornerRadius = Constants.iconContainerCornerRadius
    }

    func setupTitle(tour: QuickStartTour, completed: Bool) {
        let strikeThroughStyle = completed ? 1 : 0
        let titleColor: UIColor = completed ? .textTertiary : .label
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

    func setupColors(tour: QuickStartTour, completed: Bool) {
        mainContainerView.layer.borderColor = UIColor.textTertiary.cgColor
        descriptionLabel.textColor = Constants.descriptionLabelColor // TODO: Check if different when completed
        if completed {
            mainContainerView.backgroundColor = .clear
            iconContainerView.backgroundColor = .systemGray4
            iconView?.tintColor = UIColor(light: .white, dark: .textTertiary) // TODO: Check Dark colors
            mainContainerView.layer.borderWidth = Constants.completedTourBorderWidth
        } else {
            mainContainerView.backgroundColor = .secondarySystemBackground
            iconContainerView.backgroundColor = tour.iconColor
            iconView?.tintColor = .white
            mainContainerView.layer.borderWidth = 0
        }
    }

    func setupContent(tour: QuickStartTour) {
        descriptionLabel.text = tour.description
        iconView?.image = tour.icon.withRenderingMode(.alwaysTemplate)
    }
    
    func setupCheckmarkView(completed: Bool) {
        checkmarkImageView.image = .gridicon(.checkmark)
        checkmarkImageView.tintColor = UIColor(hexString: "AEAEB2")
        checkmarkContainerView.isHidden = !completed
    }

    enum Constants {
        static let mainContainerCornerRadius: CGFloat = 8
        static let iconContainerCornerRadius: CGFloat = 4
        static let completedTourBorderWidth: CGFloat = 0.5
        static let descriptionLabelColor: UIColor = .init(red: 0.23, green: 0.23, blue: 0.26, alpha: 0.6)
    }
}
