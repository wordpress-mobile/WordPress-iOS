import Gridicons

class QuickStartChecklistHeader: UIView {
    var collapseListener: ((Bool) -> Void)?
    var collapse: Bool = false {
        didSet {
            collapseListener?(collapse)
            /* The animation will always take the shortest way.
            *  Therefore CGFloat.pi and -CGFloat.pi animates in same position.
            *  As we need anti-clockwise rotation we forcefully made it a shortest way by using 0.999
            */
            let rotate = (collapse ? 0.999 : 180.0) * CGFloat.pi
            let alpha = collapse ? 0.0 : 1.0
            animator.animateWithDuration(0.3, animations: { [weak self] in
                self?.bottomStroke.alpha = CGFloat(alpha)
                self?.chevronView.transform = CGAffineTransform(rotationAngle: rotate)
            })
            updateCollapseHeaderAccessibility()
        }
    }
    var count: Int = 0 {
        didSet {
            titleLabel.text = String(format: Constant.title, count)
            updateCollapseHeaderAccessibility()
        }
    }

    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .body)
            titleLabel.textColor = .neutral(.shade30)
        }
    }
    @IBOutlet private var chevronView: UIImageView! {
        didSet {
            chevronView.image = Gridicon.iconOfType(.chevronDown)
            chevronView.tintColor = .textTertiary
        }
    }
    @IBOutlet var topStroke: UIView! {
        didSet {
            topStroke.backgroundColor = .divider
        }
    }
    @IBOutlet private var bottomStroke: UIView! {
        didSet {
            bottomStroke.backgroundColor = .divider
        }
    }
    @IBOutlet private var contentView: UIView! {
        didSet {
            contentView.leadingAnchor.constraint(equalTo: contentViewLeadingAnchor).isActive = true
            contentView.trailingAnchor.constraint(equalTo: contentViewTrailingAnchor).isActive = true
        }
    }

    private let animator = Animator()
    private var contentViewLeadingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? safeAreaLayoutGuide.leadingAnchor : layoutMarginsGuide.leadingAnchor
    }
    private var contentViewTrailingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? safeAreaLayoutGuide.trailingAnchor : layoutMarginsGuide.trailingAnchor
    }

    @IBAction private func headerDidTouch(_ sender: UIButton) {
        collapse.toggle()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .listForeground
        prepareForVoiceOver()
    }
}

private enum Constant {
    static let title = NSLocalizedString("Complete (%i)", comment: "The table view header title that displays the number of completed tasks")
}

// MARK: - Accessible

extension QuickStartChecklistHeader: Accessible {
    func prepareForVoiceOver() {
        // Here we explicit configure the subviews, to prepare for the desired composite behavior
        bottomStroke.isAccessibilityElement = false
        contentView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        chevronView.isAccessibilityElement = false

        // Neither the top stroke nor the button (overlay) are outlets, so we configured them in the nib

        // From an accessibility perspective, this view is essentially monolithic, so we configure it accordingly
        isAccessibilityElement = true
        accessibilityTraits = [.header, .button]

        updateCollapseHeaderAccessibility()
    }

    func updateCollapseHeaderAccessibility() {

        let accessibilityHintText: String
        let accessibilityLabelFormat: String

        if collapse {
            accessibilityHintText = NSLocalizedString("Collapses the list of completed tasks.", comment: "Accessibility hint for the list of completed tasks presented during Quick Start.")

            accessibilityLabelFormat = NSLocalizedString("Expanded, %i completed tasks, toggling collapses the list of these tasks", comment: "Accessibility description for the list of completed tasks presented during Quick Start. Parameter is a number representing the count of completed tasks.")
        } else {
            accessibilityHintText = NSLocalizedString("Expands the list of completed tasks.", comment: "Accessibility hint for the list of completed tasks presented during Quick Start.")

            accessibilityLabelFormat = NSLocalizedString("Collapsed, %i completed tasks, toggling expands the list of these tasks", comment: "Accessibility description for the list of completed tasks presented during Quick Start. Parameter is a number representing the count of completed tasks.")
        }

        accessibilityHint = accessibilityHintText

        let localizedAccessibilityDescription = String(format: accessibilityLabelFormat, arguments: [count])
        accessibilityLabel = localizedAccessibilityDescription
    }
}
