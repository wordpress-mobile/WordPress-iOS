import UIKit

class PaddedLabel: UIView {
    var padding: (horizontal: CGFloat, vertical: CGFloat) = (0, 0) {
        didSet {
            setNeedsLayout()
        }
    }

    @objc let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = bounds.insetBy(dx: padding.horizontal, dy: padding.vertical)
    }
}
