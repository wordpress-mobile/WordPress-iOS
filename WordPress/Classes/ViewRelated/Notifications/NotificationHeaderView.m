#import "NotificationHeaderView.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat const NotificationHeaderNoticonRadius    = 15.0f;
static CGFloat const NotificationHeaderNoticonPadding   = 3.0f;
static CGFloat const NotificationHeaderNoticonSize      = 30;

static CGFloat const NotificationHeaderWidthMax         = 600.0f;
static CGFloat const NotificationHeaderHeightMin        = 48.0f;

static CGFloat const NotificationHeaderSpaceTop         = 6;
static CGFloat const NotificationHeaderSpaceLeading     = 16;
static CGFloat const NotificationHeaderSpaceMiddle      = 10;
static CGFloat const NotificationHeaderSpaceTrailing    = 20;



#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NotificationHeaderView ()

@property (nonatomic, strong, readwrite) IBOutlet UIView    *containerView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel   *headerLabel;
@property (nonatomic, strong, readwrite) IBOutlet UILabel   *noticonLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIView    *noticonView;

@end


#pragma mark ====================================================================================
#pragma mark NotificationHeaderView
#pragma mark ====================================================================================

@implementation NotificationHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (void)setupSubviews
{
    UILabel *noticonLabel           = [UILabel new];
    noticonLabel.font               = [WPStyleGuide notificationBlockIconFont];
    noticonLabel.textColor          = [UIColor whiteColor];
    noticonLabel.textAlignment      = NSTextAlignmentCenter;
    self.noticonLabel               = noticonLabel;
    
    UIView *noticonView             = [UIView new];
    noticonView.layer.cornerRadius  = NotificationHeaderNoticonRadius;
    noticonView.backgroundColor     = [WPStyleGuide notificationIconColor];
    self.noticonView                = noticonView;
    
    UILabel *headerLabel            = [UILabel new];
    headerLabel.font                = [WPStyleGuide regularTextFont];
    headerLabel.textColor           = [WPStyleGuide notificationSubjectTextColor];
    headerLabel.textAlignment       = NSTextAlignmentLeft;
    headerLabel.numberOfLines       = 0;
    self.headerLabel                = headerLabel;
    
    UIView *containerView           = [UIView new];
    containerView.backgroundColor   = [WPStyleGuide notificationSubjectBackgroundColor];
    self.containerView              = containerView;
    
    // Arrange the Hierarchy
    [noticonView addSubview:noticonLabel];
    [containerView addSubview:noticonView];
    [containerView addSubview:headerLabel];
    [self addSubview:containerView];
}

- (void)setupConstraints
{
    NSDictionary *metrics = @{
        @"leading"    : @(NotificationHeaderSpaceLeading),
        @"middle"     : @(NotificationHeaderSpaceMiddle),
        @"trailing"   : @(NotificationHeaderSpaceTrailing),
        @"iconSize"   : @(NotificationHeaderNoticonSize),
        @"top"        : @(NotificationHeaderSpaceTop),
        @"bottom"     : @(NotificationHeaderSpaceTop)
    };
    
    NSDictionary *views             = NSDictionaryOfVariableBindings(_noticonView, _headerLabel);

    NSString *noticonViewFormat     = @"V:[_noticonView(==iconSize)]";
    NSString *horizontalFormat      = @"|-(leading)-[_noticonView(==iconSize)]-(middle)-[_headerLabel]-(trailing)-|";
    NSString *verticalFormat        = @"V:|-(top)-[_headerLabel]-(bottom)-|";


    // Disable tAMC, as needed
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.noticonView.translatesAutoresizingMaskIntoConstraints   = NO;
    self.noticonLabel.translatesAutoresizingMaskIntoConstraints  = NO;
    self.headerLabel.translatesAutoresizingMaskIntoConstraints   = NO;
    
    // Apply Horizontal and Vertical layouts
    [_noticonView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:noticonViewFormat
                                                                         options:0
                                                                         metrics:metrics
                                                                           views:views]];
    
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalFormat
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views]];

    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalFormat
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views]];

    // Center the noticonLabel in its container
    [_noticonView addConstraint:[NSLayoutConstraint constraintWithItem:_noticonLabel
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_noticonView
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:NotificationHeaderNoticonPadding]];
    
    [_noticonView addConstraint:[NSLayoutConstraint constraintWithItem:_noticonLabel
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:_noticonView
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0]];

    
    // Vertically center noticonView and headerLabel
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_noticonView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_containerView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_headerLabel
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_noticonView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    
    // The Height should be equal to the greater height: noticon OR headerLabel!
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:_noticonView
                                                               attribute:NSLayoutAttributeHeight
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:_headerLabel
                                                               attribute:NSLayoutAttributeHeight
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1.0
                                                                constant:NotificationHeaderHeightMin]];
    
    
    // Make sure that the containerView is pinned to the top left corner of (self).
    // Plus, let's match the width as well!
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    // Limit the width to NotificationHeaderWidthMax pixels
    if (CGRectGetWidth(self.bounds) > NotificationHeaderWidthMax) {
        [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:0.0f
                                                          constant:NotificationHeaderWidthMax]];
    } else {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                          constant:0.0]];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect frame        = self.frame;
    frame.size.height   = _containerView.frame.size.height;
    self.frame          = frame;
    
    [super layoutSubviews];
}

#pragma mark - Properties

- (NSString *)noticon
{
    return self.noticonLabel.text;
}

- (void)setNoticon:(NSString *)noticon
{
    NSAssert(self.noticonLabel, nil);
    
    self.noticonLabel.text = noticon;
    [self setNeedsLayout];
}

- (NSAttributedString *)attributedText
{
    return self.headerLabel.attributedText;
}

- (void)setAttributedText:(NSAttributedString *)text
{
    NSAssert(self.headerLabel, nil);
    
    self.headerLabel.attributedText = text;
    [self setNeedsLayout];
}

#pragma mark - Static Helpers

+ (instancetype)headerWithWidth:(CGFloat)width
{
    NotificationHeaderView *header = [[NotificationHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 0.0f)];
    
    return header;
}

@end
