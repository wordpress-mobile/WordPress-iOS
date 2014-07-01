#import "NoteBlockHeaderTableViewCell.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat const WPTableHeaderHeightMin     = 43.0f;
static CGFloat const WPTableHeaderNoticonRadius = 15.0f;

static CGFloat const WPTableHeaderTextMaxWidth  = 240.0f;
static CGFloat const WPTableHeaderHeightPadding = 5.0f;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteBlockHeaderTableViewCell ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel     *headerLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *noticonLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIView      *noticonView;

@end


#pragma mark ====================================================================================
#pragma mark NoteBlockHeaderTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockHeaderTableViewCell

- (void)awakeFromNib
{
    NSAssert(self.headerLabel, nil);
    NSAssert(self.noticonLabel, nil);
    NSAssert(self.noticonView, nil);
    
    [super awakeFromNib];
    
    self.headerLabel.font               = [WPStyleGuide regularTextFont];
    self.headerLabel.textColor          = [WPStyleGuide newKidOnTheBlockBlue];
    self.headerLabel.textAlignment      = NSTextAlignmentLeft;
    
    self.noticonView.layer.cornerRadius = WPTableHeaderNoticonRadius;
    self.noticonView.backgroundColor    = [WPStyleGuide notificationIconColor];
    self.noticonLabel.font              = [WPStyleGuide notificationBlockIconFont];
    self.noticonLabel.textColor         = [UIColor whiteColor];
    
    self.backgroundColor                = [WPStyleGuide notificationSubjectBackgroundColor];
    self.selectionStyle                 = UITableViewCellSelectionStyleNone;
    self.accessoryType                  = UITableViewCellAccessoryNone;
}

- (void)setNoticon:(NSString *)noticon
{
    self.noticonLabel.text = noticon;
    _noticon = noticon;
}

- (void)setAttributedText:(NSAttributedString *)text
{
    self.headerLabel.attributedText = text;
    _attributedText = text;
}


#pragma mark - NoteBlockTableViewCell Methods

+ (CGFloat)heightWithText:(NSString *)text
{
	NSDictionary *attributes	= @{ NSFontAttributeName: [WPStyleGuide regularTextFont] };
	CGRect rect					= [text boundingRectWithSize:CGSizeMake(WPTableHeaderTextMaxWidth, MAXFLOAT)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
	
	return MAX(ceil(rect.size.height + WPTableHeaderHeightPadding * 2.0f), WPTableHeaderHeightMin);
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
