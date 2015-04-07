import Foundation


@objc public class NoteTableHeaderView : UIView
{
    // MARK: - Public Properties
    public var title: String? {
        set {
            // For layout reasons, we need to ensure that the titleLabel uses an exact Paragraph Height!
            if let unwrappedTitle = newValue?.uppercaseString {
                titleLabel.attributedText = NSAttributedString(string: unwrappedTitle, attributes: Style.sectionHeaderRegularStyle)
                setNeedsLayout()
            }
        }
        get {
            return titleLabel.text
        }
    }
    
    public var separatorColor: UIColor? {
        set {
            topSeparator.backgroundColor    = newValue
            bottomSeparator.backgroundColor = newValue
        }
        get {
            return topSeparator.backgroundColor
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
                super.frame.origin.x    = (frame.width - maximumWidth) * 0.5
                super.frame.size.width  = maximumWidth
            }
        }
    }
    
    // MARK: - View Methods
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let frameWidth              = frame.width
        let frameHeight             = NoteTableHeaderView.headerHeight()
        let imageOriginY            = floor((frameHeight - imageView.frame.height) * 0.5)
        let titleWidth              = frameWidth - (imageOriginX * 2) - imageView.frame.width
        let titleOriginY            = floor((frameHeight - titleHeight) * 0.5)
        let bottomSeparatorY        = frameHeight - separatorHeight
        
        if frameWidth > maximumWidth {
            frame.origin.x          = (frameWidth - maximumWidth) * 0.5;
        }
        
        frame.size.height           = frameHeight
        
        imageView.frame.origin      = CGPoint(x: imageOriginX, y: imageOriginY)
        
        titleLabel.frame.origin     = CGPoint(x: titleOriginX, y: titleOriginY)
        titleLabel.frame.size       = CGSize(width: titleWidth, height: titleHeight)
        
        topSeparator.frame          = CGRect(x: 0, y: 0,                width: frameWidth, height: separatorHeight)
        bottomSeparator.frame       = CGRect(x: 0, y: bottomSeparatorY, width: frameWidth, height: separatorHeight)
    }
    
    // MARK - Private Helpers
    private func setupSubviews() {
        backgroundColor             = Style.sectionHeaderBackgroundColor
        
        titleLabel                  = UILabel()
        titleLabel.textAlignment    = .Left
        titleLabel.numberOfLines    = 0;
        titleLabel.lineBreakMode    = .ByWordWrapping
        titleLabel.backgroundColor  = UIColor.clearColor()
        titleLabel.shadowOffset     = CGSizeZero
        addSubview(titleLabel)
        
        let image                   = UIImage(named: imageName)
        imageView                   = UIImageView(image: image)
        imageView.sizeToFit()
        addSubview(imageView)

        topSeparator                = UIView(frame: CGRectZero)
        addSubview(topSeparator)
        
        bottomSeparator             = UIView(frame: CGRectZero)
        addSubview(bottomSeparator)
    }

    
    // MARK: - Constants
    private let imageOriginX        = CGFloat(10)
    private let titleOriginX        = CGFloat(30)
    private let titleHeight         = CGFloat(16)
    private let imageName           = "reader-postaction-time"
    
    private let separatorHeight     = CGFloat(1) / UIScreen.mainScreen().scale
    private let maximumWidth        = UIDevice.isPad() ? WPTableViewFixedWidth : CGFloat.max
    
    // MARK: - Properties
    private var topSeparator:       UIView!
    private var bottomSeparator:    UIView!
    
    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications
    
    // MARK: - Outlets
    private var imageView:          UIImageView!
    private var titleLabel:         UILabel!
}
