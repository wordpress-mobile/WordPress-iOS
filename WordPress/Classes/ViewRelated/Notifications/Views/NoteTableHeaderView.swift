import Foundation


@objc public class NoteTableHeaderView : UIView
{
    // MARK: - Public Properties
    public var title: String? {
        didSet {
            titleLabel.text = title?.uppercaseString ?? String()
            setNeedsLayout()
        }
    }
    
    public var separatorColor: UIColor? {
        didSet {
            topSeparator.backgroundColor    = separatorColor ?? UIColor.clearColor()
            bottomSeparator.backgroundColor = separatorColor ?? UIColor.clearColor()
        }
    }
    
    // MARK: - Public Methods
    public class func headerHeight() -> CGFloat {
        let cellHeight = CGFloat(26)
        return cellHeight
    }
    
    // MARK: - Convenience Inits
    public convenience init(width: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.init(frame: frame)
        setupSubviews()
    }
    
    // MARK: - Overriden Properties
    public override var frame: CGRect {
        didSet {
            if frame.width > maximumWidth {
                super.frame.origin.x = (frame.width - maximumWidth) * 0.5
                super.frame.size.width = maximumWidth
            }
        }
    }
    
    // MARK: - View Methods
    public override func layoutSubviews() {
        super.layoutSubviews()
        let width = frame.width
        if width > maximumWidth {
            frame.origin.x  = (width - maximumWidth) * 0.5;
        }
        
        frame.size.height           = NoteTableHeaderView.headerHeight()
        imageView.frame.origin      = imageOrigin
        
        titleLabel.frame.origin     = titleOrigin
        titleLabel.frame.size       = CGSize(width: bounds.width - imageOrigin.x * 2 - imageView.frame.width, height: titleHeight)
        
        topSeparator.frame          = CGRect(x: 0, y: 0, width: bounds.width, height: separatorHeight)
        bottomSeparator.frame       = CGRect(x: 0, y: bounds.height, width: bounds.width, height: separatorHeight)
    }
    
    // MARK - Private Helpers
    private func setupSubviews() {
        backgroundColor             = WPStyleGuide.Notifications.headerBackgroundColor
        
        titleLabel                  = UILabel()
        titleLabel.textAlignment    = .Left
        titleLabel.numberOfLines    = 0;
        titleLabel.lineBreakMode    = .ByWordWrapping
        titleLabel.font             = WPStyleGuide.Notifications.headerFont
        titleLabel.textColor        = WPStyleGuide.Notifications.headerTextColor
        titleLabel.backgroundColor  = UIColor.clearColor()
        titleLabel.shadowOffset     = CGSizeZero
        addSubview(titleLabel)
        
        let image                   = UIImage(named: imageName)
        imageView                   = UIImageView(image: image)
        imageView.sizeToFit()
        addSubview(imageView)

        topSeparator                = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: separatorHeight))
        addSubview(topSeparator)
        
        bottomSeparator             = UIView(frame: CGRect(x: 0, y: bounds.height, width: bounds.width, height: separatorHeight))
        addSubview(bottomSeparator)
    }

    
    // MARK: - Constants
    private let imageOrigin     = CGPoint(x: 10, y: 5)
    private let titleOrigin     = CGPoint(x: 30, y: 4)
    private let titleHeight     = CGFloat(16)
    private let imageName       = "reader-postaction-time"
    
    private let separatorHeight = CGFloat(1) / UIScreen.mainScreen().scale
    private let maximumWidth    = UIDevice.isPad() ? WPTableViewFixedWidth : CGFloat.max
    
    // MARK: - Properties
    private var topSeparator:       UIView!
    private var bottomSeparator:    UIView!
    
    // MARK: - Outlets
    private var imageView:          UIImageView!
    private var titleLabel:         UILabel!
}
