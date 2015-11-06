import Foundation

// Makes a UIImageView circular. Handy for gravatars
public class CircularImageView : UIImageView
{
    public var shouldRoundCorners : Bool = true {
        didSet {
            let rect = frame;
            frame = rect;
        }
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        layer.masksToBounds = true
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true
    }

    override public init(image: UIImage!) {
        super.init(image: image)
        
        layer.masksToBounds = true
    }
    
    convenience public init() {
        self.init(frame: CGRectZero)
    }

    override public var frame: CGRect {
        didSet {
            refreshRadius()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        refreshRadius()
    }
    
    private func refreshRadius() {
        layer.cornerRadius = shouldRoundCorners ? (frame.width * 0.5) : 0
    }
}
