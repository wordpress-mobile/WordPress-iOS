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
        }
    }
    var count: Int = 0 {
        didSet {
            titleLabel.text = String(format: Constant.title, count)
        }
    }

    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .body)
            titleLabel.textColor = WPStyleGuide.grey()
        }
    }
    @IBOutlet private var chevronView: UIImageView! {
        didSet {
            chevronView.image = Gridicon.iconOfType(.chevronDown)
            chevronView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()
        }
    }
    @IBOutlet private var bottomStroke: UIView!
    @IBOutlet private var contentView: UIView! {
        didSet {
            contentView.leadingAnchor.constraint(equalTo: contentViewLeadingAnchor).isActive = true
            contentView.trailingAnchor.constraint(equalTo: contentViewTrailingAnchor).isActive = true
        }
    }

    private let animator = Animator()
    private var contentViewLeadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return WPDeviceIdentification.isiPhone() ? safeAreaLayoutGuide.leadingAnchor : layoutMarginsGuide.leadingAnchor
        }
        return WPDeviceIdentification.isiPhone() ? leadingAnchor : layoutMarginsGuide.leadingAnchor
    }
    private var contentViewTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return WPDeviceIdentification.isiPhone() ? safeAreaLayoutGuide.trailingAnchor : layoutMarginsGuide.trailingAnchor
        }
        return WPDeviceIdentification.isiPhone() ? trailingAnchor : layoutMarginsGuide.trailingAnchor
    }

    @IBAction private func headerDidTouch(_ sender: UIButton) {
        collapse.toggle()
    }
}

private enum Constant {
    static let title = NSLocalizedString("Complete (%i)", comment: "The table view header title that displays the number of completed tasks")
}
