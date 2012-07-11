/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import "SidebarSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#import "Constants.h"
#import "PanelNavigationConstants.h"

@interface SidebarSectionHeaderView (Private)
-(void)receivedCommentsChangedNotification:(NSNotification*)aNotification;
-(void)updatePendingCommentsIcon;
-(void)updateGradient;
-(CGRect)titleLabelFrame:(BOOL)isBadgeVisible;
@end

CGFloat const BlavatarHeight = 32.f;
CGFloat const BadgeHeight = 24.f;
    
@implementation SidebarSectionHeaderView


@synthesize titleLabel=_titleLabel, disclosureButton=_disclosureButton, delegate=_delegate, sectionInfo=_sectionInfo, numberOfCommentsImageView=_numberOfCommentsImageView, blog = _blog, numberOfcommentsLabel = _numberOfcommentsLabel;

+ (Class)layerClass {
    
    return [CAGradientLayer class];
}

-(id)initWithFrame:(CGRect)frame blog:(Blog*)blog sectionInfo:(SectionInfo *)sectionInfo delegate:(id <SidebarSectionHeaderViewDelegate>)delegate {
    
    self = [super initWithFrame:frame];
    startingFrameWidth = frame.size.width;
    
    if (self != nil) {
        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];
        [tapGesture release];
        
        _blog = blog;
        _delegate = delegate;        
        self.userInteractionEnabled = YES;
        
        CGFloat blavatarOffset = (frame.size.height - BlavatarHeight) / 2.f;
        blavatarView = [[UIImageView alloc] initWithFrame:CGRectMake(blavatarOffset, blavatarOffset, BlavatarHeight, BlavatarHeight)];
        [blavatarView setAlpha:0.65f];
        [blavatarView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        [self addSubview: blavatarView];
        
        int numberOfPendingComments = [blog numberOfPendingComments];
      
        // Create and configure the title label.
        self.sectionInfo = sectionInfo;
        CGRect titleLabelFrame = [self titleLabelFrame:(numberOfPendingComments > 0 )];
                   
        CGRectInset(titleLabelFrame, 0.0, 6.0);
        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        
        //set the title of the blog        
        NSString *blogName = blog.blogName;
        if (blogName != nil && ! [@"" isEqualToString: [blogName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
            label.text = blogName;
        else
            label.text = [blog hostURL];            
        
        label.font = [UIFont systemFontOfSize:17.0];
        label.textColor = [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0];
        label.shadowOffset = CGSizeMake(0, 1.1f);
        label.shadowColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _titleLabel = label;
        
        CGRect commentsBadgedRect = IS_IPAD ? CGRectMake(self.bounds.size.width - 48.0 , (frame.size.height - BadgeHeight) / 2.f, 34.0, BadgeHeight ) : CGRectMake(self.bounds.size.width - 88.0 ,  (frame.size.height - BadgeHeight) / 2.f, 34.0, BadgeHeight);
        UIImageView *commentsIconImgView = [[[UIImageView alloc] initWithFrame:commentsBadgedRect] autorelease];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [UIImage imageNamed:@"sidebar_comment_bubble"];
            commentsIconImgView.image = img;
        }
        [self addSubview:commentsIconImgView];
        _numberOfCommentsImageView = commentsIconImgView;
        
        UILabel *commentsLbl = [[UILabel alloc]initWithFrame:commentsBadgedRect];
        commentsLbl.backgroundColor = [UIColor clearColor];
        commentsLbl.textAlignment = UITextAlignmentCenter;
        if (numberOfPendingComments > 0) {
            commentsLbl.text = (numberOfPendingComments > 99) ? NSLocalizedString(@"99⁺", "") : [NSString stringWithFormat:@"%d", numberOfPendingComments];
        } else {
            commentsLbl.text = nil;
        }
        commentsLbl.font = [UIFont systemFontOfSize:17.0];
        commentsLbl.textColor = [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0];
        commentsLbl.shadowOffset = CGSizeMake(0, 1.1f);
        commentsLbl.shadowColor = [UIColor blackColor];
        CGRect frame = commentsLbl.frame;
        frame.origin.y = 7.0f;
        commentsLbl.frame = frame;
        [self addSubview:commentsLbl];
        _numberOfcommentsLabel = commentsLbl;
        
        // Create and configure the disclosure button.
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = IS_IPAD ? CGRectMake(self.frame.size.width - 31.0, 6.0, 35.0, 35.0) : CGRectMake(self.frame.size.width - 80.0, 8.0, 35.0, 35.0);
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        _disclosureButton = button;

        [self updateGradient];
        
        background = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"sidebar_cell_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        background.frame = self.frame;
        [self addSubview:background];
        [self sendSubviewToBack:background];
        
        // we need a background color in order to make the cell incertion/deletion animation look nice
        // since sidebar_cell_bg is transparent 
        //self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg"]];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCommentsChangedNotification:) 
                                                 name:kCommentsChangedNotificationName
                                               object:self.blog];
    return self;
}

-(CGRect)titleLabelFrame:(BOOL)isBadgeVisible {
    CGRect titleLabelFrame = self.bounds;
    titleLabelFrame.size.width = startingFrameWidth;    
    titleLabelFrame.origin.x = 49.f; // Aligns to row labels
    
    if ( IS_IPAD ) {
        if ( isBadgeVisible ) 
            titleLabelFrame.size.width -= ( 31 + 48 + titleLabelFrame.origin.x ); //the disclosure size + comment badge rect + blavatar size;
        else
            titleLabelFrame.size.width -= ( 31 + titleLabelFrame.origin.x ); //the disclosure size + blavatar size
    } else {
        if ( isBadgeVisible ) 
            titleLabelFrame.size.width -= ( DETAIL_LEDGE + 4  + 48 + titleLabelFrame.origin.x ); //ledge + padding + comment badge rect + blavatar size;
        else
            titleLabelFrame.size.width -= ( DETAIL_LEDGE + 4 + titleLabelFrame.origin.x ); //ledge + padding + blavatar size
    }
         
    return titleLabelFrame;
}

-(IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}

-(void)updatePendingCommentsIcon {
    if( self.disclosureButton.selected ) {
        self.numberOfCommentsImageView.image = nil;
        self.numberOfcommentsLabel.text = nil;
        self.titleLabel.frame = [self titleLabelFrame:NO];
    } else {
        //update the #s of pending comments and the size of title label.
        int numberOfPendingComments = [_blog numberOfPendingComments];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [UIImage imageNamed:@"sidebar_comment_bubble"];
            self.numberOfCommentsImageView.image = img;
            self.numberOfcommentsLabel.text = [NSString stringWithFormat:@"%d", numberOfPendingComments];
        } else {
            self.numberOfCommentsImageView.image = nil;
            self.numberOfcommentsLabel.text = nil;
        }
        self.titleLabel.frame = [self titleLabelFrame:(numberOfPendingComments > 0)];
    }
}

- (void)receivedCommentsChangedNotification:(NSNotification*)aNotification {
    [self updatePendingCommentsIcon];
}

-(void)toggleOpenWithUserAction:(BOOL)userAction {
    
    // Don't allow section to be collapsed if it is already open
    if (userAction && self.disclosureButton.selected)
        return;
    
    // Toggle the disclosure button state.
    self.disclosureButton.selected = !self.disclosureButton.selected;
    
    //change the comments icon
    [self updatePendingCommentsIcon];
    [self updateGradient];
    
    if (self.disclosureButton.selected) {
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [blavatarView setAlpha:1.0f];
    }
    else {
        [self.titleLabel setTextColor:[UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0]];
        [blavatarView setAlpha:0.65f];
    }
    
    // If this was a user action, send the delegate the appropriate message.
    if (userAction) {
        if (self.disclosureButton.selected) {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [self.delegate sectionHeaderView:self sectionOpened:self.sectionInfo];
            }
        }
        /*else {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [self.delegate sectionHeaderView:self sectionClosed:self.sectionInfo];
            }
        }*/
    }
}

- (void)updateGradient {
    CAGradientLayer *gradient = (CAGradientLayer *)self.layer;
    CGColorRef startColor, endColor;
    if (self.disclosureButton.selected) {
        startColor = [[UIColor colorWithWhite:0.6f alpha:0.3f] CGColor];
        endColor = [[UIColor colorWithWhite:0.6f alpha:0.0f] CGColor];
    } else {
        startColor = [[UIColor colorWithWhite:0.6f alpha:0.15f] CGColor];
        endColor = [[UIColor colorWithWhite:0.6f alpha:0.f] CGColor];
    }
    gradient.colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [background release];
    [blavatarView release];
    [super dealloc];
}

@end
