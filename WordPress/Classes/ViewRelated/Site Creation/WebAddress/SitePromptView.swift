import UIKit

class SitePromptView: UIView {

    private struct Parameters {
        static let shadowOffset = CGSize(width: 0, height: 5)
        static let shadowOpacity = Float(0.2)
        static let shadowRadius = CGFloat(8)
        static let cornerRadius = CGFloat(8)
    }

    @IBOutlet var views: [UIView]! {
        didSet {
            views.forEach { (view) in
                view.backgroundColor = .listBackground
            }
        }
    }

    @IBOutlet weak var lockIcon: UIImageView! {
        didSet {
            lockIcon.tintColor = .textSubtle
        }
    }

    @IBOutlet weak var sampleAddress: UILabel! {
        didSet {
            sampleAddress.textColor = .textSubtle
            sampleAddress.font = WPStyleGuide.fontForTextStyle(.footnote)
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

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = Parameters.shadowOffset
        layer.shadowOpacity = Parameters.shadowOpacity
        layer.shadowRadius = Parameters.shadowRadius
        contentView.layer.cornerRadius = Parameters.cornerRadius
    }
}
