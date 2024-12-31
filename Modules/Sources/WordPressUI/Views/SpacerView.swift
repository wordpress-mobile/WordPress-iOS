import UIKit

public final class SpacerView: UIView {
    public convenience init(minWidth: CGFloat) {
        self.init()

        widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
    }

    public convenience init(minHeight: CGFloat) {
        self.init()

        heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    }

    public convenience init(width: CGFloat) {
        self.init()

        widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    public convenience init(height: CGFloat) {
        self.init()

        heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    public override init(frame: CGRect) {
        super.init(frame: .zero)

        // Make sure it compresses or expands before any other views if needed.
        setContentCompressionResistancePriority(.init(10), for: .horizontal)
        setContentCompressionResistancePriority(.init(10), for: .vertical)
        setContentHuggingPriority(.init(10), for: .horizontal)
        setContentHuggingPriority(.init(10), for: .vertical)
    }

    public override var intrinsicContentSize: CGSize {
        CGSizeMake(0, 0) // Avoid ambiguous layout
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public class var layerClass: AnyClass {
        CATransformLayer.self // Draws nothing
    }

    override public var backgroundColor: UIColor? {
        get { return nil }
        set { /* Do nothing */ }
    }
}
