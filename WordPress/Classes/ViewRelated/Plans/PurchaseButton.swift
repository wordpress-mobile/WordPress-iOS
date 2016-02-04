import UIKit
import MRProgress

@IBDesignable
class PurchaseButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            updateAppearance()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAppearance()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setTitleColor(UIColor.whiteColor(), forState: [.Highlighted])
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 19.0, bottom: 10.0, right: 19.0)
        
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.CGColor
        layer.borderColor = tintColor.CGColor
        
        setTitleColor(tintColor, forState: .Normal)
        
        setBackgroundImage(UIImage(color: tintColor), forState: .Highlighted)
    }
}
