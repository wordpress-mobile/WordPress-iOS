import UIKit
import Gridicons

class SitePromptView: UIView {

    private struct Parameters {
        static let cornerRadius = CGFloat(8)
        static let borderWidth = CGFloat(1)
        static let borderColor = UIColor.primaryButtonBorder
    }

    @IBOutlet weak var sitePrompt: UILabel! {
        didSet {
            sitePrompt.text = NSLocalizedString("example.com", comment: "Provides a sample of what a domain name looks like.")
        }
    }

    @IBOutlet weak var lockIcon: UIImageView! {
        didSet {
            lockIcon.image = UIImage.gridicon(.lock)
        }
    }
    var contentView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            contentView.layer.borderColor = Parameters.borderColor.cgColor
        }
    }

    private func commonInit() {
        let bundle = Bundle(for: SitePromptView.self)
        guard
            let nibViews = bundle.loadNibNamed("SitePromptView", owner: self, options: nil),
            let loadedView = nibViews.first as? UIView
        else {
            return
        }

        contentView = loadedView
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            contentView.constrainToSuperViewEdges()
        )
        contentView.layer.cornerRadius = Parameters.cornerRadius
        contentView.layer.borderColor = Parameters.borderColor.cgColor
        contentView.layer.borderWidth = Parameters.borderWidth
    }
}
