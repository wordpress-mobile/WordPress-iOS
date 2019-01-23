import Gridicons


class QuickStartChecklistHeader: UIView {
    var collapseListener: ((Bool) -> Void)?
    var collapse: Bool = false {
        didSet {
            collapseListener?(collapse)
            let rotate = (collapse ? 180.0 : 0.999) * CGFloat.pi
            let alpha = collapse ? 0.0 : 1.0
            animator.animateWithDuration(0.3, animations: { [weak self] in
                self?.bottomStroke.alpha = CGFloat(alpha)
                self?.chevronView.transform = CGAffineTransform(rotationAngle: rotate)
            })
        }
    }
    var count: Int = 0 {
        didSet {
            titleLabel.text = String(format: "Complete (%i)", count)
        }
    }

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var bottomStroke: UIView!
    @IBOutlet private var chevronView: UIImageView!

    private let animator = Animator()


    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.configureLabel(titleLabel, textStyle: .body)
        titleLabel.textColor = WPStyleGuide.grey()
        chevronView.image = Gridicon.iconOfType(.chevronDown)
        chevronView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()
    }

    @IBAction func headerDidTouch(_ sender: UIButton) {
        collapse.toggle()
    }
}
