import UIKit

class PaddedLabel: UIView {
    var text: String? {
        get {
            return label.text
        }

        set {
            label.text = newValue
        }
    }

    var textColor: UIColor {
        get {
            return label.textColor
        }

        set {
            label.textColor = newValue
        }
    }

    var font: UIFont {
        get {
            return label.font
        }

        set {
            label.font = newValue
        }
    }

    var textAlpha: CGFloat {
        get {
            return label.alpha
        }

        set {
            label.alpha = newValue
        }
    }

    var padding: (horizontal: CGFloat, vertical: CGFloat) = (0,0) {
        didSet {
            setNeedsLayout()
        }
    }

    private let label = UILabel()

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

        label.frame = CGRectInset(bounds, padding.horizontal, padding.vertical)
    }
}
