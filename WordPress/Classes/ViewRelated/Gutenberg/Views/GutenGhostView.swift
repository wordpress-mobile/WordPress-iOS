import UIKit

class GutenGhostView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    @IBOutlet weak private var inserterView: UIView! {
        didSet {
            inserterView.layer.cornerRadius = inserterView.frame.height / 2
            inserterView.clipsToBounds = true
        }
    }

    @IBOutlet private var roundedCornerViews: [UIView]! {
        didSet {
            roundedCornerViews.forEach { (view) in
                view.layer.cornerRadius = 6
                view.clipsToBounds = true
            }
        }
    }

    func startAnimation() {
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        startGhostAnimation(style: style)
    }

    private func commonInit() {
        let bundle = Bundle(for: GutenGhostView.self)
        guard
            let nibViews = bundle.loadNibNamed("GutenGhostView", owner: self, options: nil),
            let contentView = nibViews.first as? UIView
        else {
            return
        }

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            contentView.constrainToSuperViewEdges()
        )
    }
}
