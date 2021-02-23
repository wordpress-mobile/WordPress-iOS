import UIKit
import Gridicons

class SitePromptView: UIView {

    private struct Parameters {
        static let cornerRadius = CGFloat(8)
        static let borderWidth = CGFloat(1)
    }

    @IBOutlet weak var lockIcon: UIImageView! {
        didSet {
            lockIcon.image = UIImage.gridicon(.lock)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let bundle = Bundle(for: SitePromptView.self)
        guard
            let nibViews = bundle.loadNibNamed("SitePromptView", owner: self, options: nil),
            let contentView = nibViews.first as? UIView
        else {
            return
        }

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            contentView.constrainToSuperViewEdges()
        )
        contentView.layer.cornerRadius = Parameters.cornerRadius
        contentView.layer.borderColor = UIColor.primaryButtonBorder.cgColor
        contentView.layer.borderWidth = Parameters.borderWidth
    }
}
