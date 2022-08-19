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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
        backgroundColor = .clear
        mainContainerView.layer.cornerRadius = Constants.mainContainerCornerRadius
        iconContainerView.layer.cornerRadius = Constants.iconContainerCornerRadius
        mainContainerView.layer.borderColor = Constants.borderColor.cgColor
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
        descriptionLabel.textColor = .secondaryLabel
        if completed {
            mainContainerView.backgroundColor = .clear
            iconContainerView.backgroundColor = .systemGray4
            iconView?.tintColor = Constants.iconTintColor
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
        descriptionContainerView.isHidden = !tour.showDescriptionInQuickStartModal
        iconView?.image = tour.icon.withRenderingMode(.alwaysTemplate)
    }

    func setupCheckmarkView(completed: Bool) {
        checkmarkImageView.image = .gridicon(.checkmark)
        checkmarkImageView.tintColor = Constants.checkmarkColor
        checkmarkContainerView.isHidden = !completed
    }

    enum Constants {
        static let mainContainerCornerRadius: CGFloat = 8
        static let iconContainerCornerRadius: CGFloat = 4
        static let completedTourBorderWidth: CGFloat = 0.5
        static let borderColor = UIColor(light: UIColor(hexString: "3c3c43")?.withAlphaComponent(0.36) ?? .clear,
                                         dark: UIColor(hexString: "545458")?.withAlphaComponent(0.65) ?? .clear)
        static let iconTintColor = UIColor(light: .white,
                                           dark: UIColor(hexString: "636366") ?? .clear)
        static let checkmarkColor = UIColor(light: UIColor(hexString: "AEAEB2") ?? .clear,
                                            dark: UIColor(hexString: "636366") ?? .clear)
    }
}
