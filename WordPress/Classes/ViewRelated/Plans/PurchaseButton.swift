import UIKit
import MRProgress

@IBDesignable
class RoundedButton: UIButton {
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
    
    @IBInspectable var horizontalEdgeInset: CGFloat = 19.0 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable var verticalEdgeInset: CGFloat = 10.0 {
        didSet {
            updateAppearance()
        }
    }
    
    override var reversesTitleShadowWhenHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAppearance()
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        contentEdgeInsets = UIEdgeInsets(top: verticalEdgeInset, left: horizontalEdgeInset, bottom: verticalEdgeInset, right: horizontalEdgeInset)
        
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.CGColor
        
        setTitleColor(tintColor, forState: .Normal)
        
        if reversesTitleShadowWhenHighlighted {
            setTitleColor(backgroundColor, forState: [.Highlighted])
            setBackgroundImage(UIImage(color: tintColor), forState: .Highlighted)
        } else {
            setTitleColor(tintColor.colorWithAlphaComponent(0.3), forState: .Highlighted)
        }
    }
}

class PurchaseButton: RoundedButton {
    var animatesWhenSelected: Bool = true

    private var collapseConstraint: NSLayoutConstraint!
    private lazy var activityIndicatorView: MRActivityIndicatorView = {
        let activityView = MRActivityIndicatorView(frame: self.bounds)
        activityView.tintColor = self.tintColor
        activityView.lineWidth = 1.0
        
        self.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        
        self.pinSubviewAtCenter(activityView)
        activityView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        activityView.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
        activityView.widthAnchor.constraintEqualToAnchor(activityView.heightAnchor).active = true

        return activityView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collapseConstraint = widthAnchor.constraintEqualToAnchor(heightAnchor)
    }
    
    private var _cornerRadius: CGFloat = 0
    override var selected: Bool {
        didSet {
            if oldValue == selected { return }
            
            if selected {
                collapseConstraint.active = true

                UIView.animateWithDuration(0.3, animations: {
                    // Save the corner radius so we can restore it later
                    self._cornerRadius = self.cornerRadius
                    self.cornerRadius = self.bounds.height / 2
                    self.titleLabel?.alpha = 0
                    
                    self.layoutIfNeeded()
                    }, completion:  { finished in
                        self.activityIndicatorView.startAnimating()
                        self.borderWidth = 0
                })
            } else {
                collapseConstraint.active = false
                
                self.activityIndicatorView.stopAnimating()
                
                UIView.animateWithDuration(0.3, animations: {
                    self.cornerRadius = self._cornerRadius
                    self.borderWidth = 1
                    
                    self.layoutIfNeeded()
                    }, completion:  { finished in
                        self.titleLabel?.alpha = 1
                })
            }
        }
    }
}
