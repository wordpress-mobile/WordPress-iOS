import Foundation
import UIKit


public class NavigationTitleView : UIView
{
    public let titleLabel       = UILabel(frame: defaultTitleFrame)
    public let subtitleLabel    = UILabel(frame: defaultSubtitleFrame)
    
    
    // MARK: - UIView's Methods
    convenience init() {
        self.init(frame: NavigationTitleView.defaultViewFrame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    
    // MARK: - Helpers
    private func setupSubviews() {
        titleLabel.font                 = WPFontManager.openSansSemiBoldFontOfSize(NavigationTitleView.defaultTitleFontSize)
        titleLabel.textColor            = UIColor.whiteColor()
        titleLabel.textAlignment        = .Center
        titleLabel.backgroundColor      = UIColor.clearColor()
        titleLabel.autoresizingMask     = UIViewAutoresizing.FlexibleWidth
        
        subtitleLabel.font              = WPFontManager.openSansRegularFontOfSize(NavigationTitleView.defaultSubtitleFontSize)
        subtitleLabel.textColor         = UIColor.whiteColor()
        subtitleLabel.textAlignment     = .Center
        subtitleLabel.backgroundColor   = UIColor.clearColor()
        subtitleLabel.autoresizingMask  = UIViewAutoresizing.FlexibleWidth;

        backgroundColor                 = UIColor.clearColor()
        autoresizingMask                = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleTopMargin
        clipsToBounds                   = true
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    // MARK: - Static Constants
    private static let defaultViewFrame         = CGRect(x: 0.0, y: 0.0, width: 200.0, height: 35.0)
    
    private static let defaultTitleFontSize     = CGFloat(15)
    private static let defaultTitleFrame        = CGRect(x: 0.0, y: 0.0,  width: 200.0, height: 19.0)
    
    private static let defaultSubtitleFontSize  = CGFloat(10)
    private static let defaultSubtitleFrame     = CGRect(x: 0.0, y: 19.0, width: 200.0, height: 16.0)
}
