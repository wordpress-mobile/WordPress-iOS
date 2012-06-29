/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import "SidebarSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#import "PanelNavigationConstants.h"

@interface SidebarSectionHeaderView (Private)
-(UIImage *)badgeImage:(UIImage *)img withText:(NSString *)text1;
-(void)receivedCommentsChangedNotification:(NSNotification*)aNotification;
-(void)updatePendingCommentsIcon;
-(CGRect)titleLabelFrame:(BOOL)isBadgeVisible;
@end
    
    
@implementation SidebarSectionHeaderView


@synthesize titleLabel=_titleLabel, disclosureButton=_disclosureButton, delegate=_delegate, sectionInfo=_sectionInfo, numberOfCommentsImageView=_numberOfCommentsImageView, blog = _blog;


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
        
        UIImageView *blavatarView = [[[UIImageView alloc] initWithFrame:CGRectMake(6.0, 6.0, 35.0, 35.0)] autorelease];
        [blavatarView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        [self addSubview:blavatarView];
        
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
        
        label.font = [UIFont boldSystemFontOfSize:17.0];
        label.textColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1.1f);
        label.shadowColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _titleLabel = label;
        
        CGRect commentsBadgedRect = IS_IPAD ? CGRectMake(self.bounds.size.width - ( 31.0 + 35.0 ) , 6.0, 35.0, 35.0) : CGRectMake(self.bounds.size.width - ( 65.0 + DETAIL_LEDGE + 4 ), 6.0, 35.0, 35.0);
        UIImageView *commentsIconImgView = [[[UIImageView alloc] initWithFrame:commentsBadgedRect] autorelease];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [self badgeImage:[UIImage imageNamed:@"inner-shadow.png"] withText:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            commentsIconImgView.image = img;
        }
        [self addSubview:commentsIconImgView];
        _numberOfCommentsImageView = commentsIconImgView;
        
        // Create and configure the disclosure button.
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = IS_IPAD ? CGRectMake(self.frame.size.width - 31.0, 6.0, 35.0, 35.0) : CGRectMake(self.frame.size.width - 80.0, 8.0, 35.0, 35.0);
        [button setImage:[UIImage imageNamed:@"sidebar_expand_down"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sidebar_expand_up"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        _disclosureButton = button;
        
        background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sidebar_cell_bg"]];
        [self addSubview:background];
        [self sendSubviewToBack:background];
        
        // we need a background color in order to make the cell incertion/deletion animation look nice
        // since sidebar_cell_bg is transparent 
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg"]];
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
    titleLabelFrame.origin.x += 47.0; //blavatar size 
    
    if ( IS_IPAD ) {
        if ( isBadgeVisible ) 
            titleLabelFrame.size.width -= ( 31 + 35 + 47 ); //the disclosure size + comment badge + blavatar size;
        else
            titleLabelFrame.size.width -= ( 31 + 47 ); //the disclosure size + blavatar size
    } else {
        if ( isBadgeVisible ) 
            titleLabelFrame.size.width -= ( DETAIL_LEDGE + 4  + 35 + 47 ); //ledge + padding + comment badge + blavatar size;
        else
            titleLabelFrame.size.width -= ( DETAIL_LEDGE + 4 + 47 ); //ledge + padding + blavatar size
    }
         
    return titleLabelFrame;
}

-(IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}

-(void)updatePendingCommentsIcon {
    if( self.disclosureButton.selected ) {
        self.numberOfCommentsImageView.image = nil;    
        self.titleLabel.frame = [self titleLabelFrame:NO];
    } else {
        //update the #s of pending comments and the size of title label.
        int numberOfPendingComments = [_blog numberOfPendingComments];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [self badgeImage:[UIImage imageNamed:@"inner-shadow.png"] withText:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            self.numberOfCommentsImageView.image = img;
        } else {
            self.numberOfCommentsImageView.image = nil;
        }
        self.titleLabel.frame = [self titleLabelFrame:(numberOfPendingComments > 0)];
    }
}

//Add text to UIImage - ref: http://iphonesdksnippets.com/post/2009/05/05/Add-text-to-image-(UIImage).aspx
-(UIImage *)badgeImage:(UIImage *)img withText:(NSString *)text1{ 
    int w = img.size.width; 
    int h = img.size.height; 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst); 
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage); 
    
    char* text= (char *)[text1 cStringUsingEncoding:NSASCIIStringEncoding]; 
    CGContextSelectFont(context, "Arial", 17, kCGEncodingMacRoman); 
    CGContextSetTextDrawingMode(context, kCGTextFill); 
    CGContextSetRGBFillColor(context, 0, 0, 0, 1); 
    CGContextShowTextAtPoint(context,10,10,text, strlen(text)); 
    CGImageRef imgCombined = CGBitmapContextCreateImage(context); 
    
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace); 
    
    UIImage *retImage = [UIImage imageWithCGImage:imgCombined]; 
    CGImageRelease(imgCombined); 
    
    return retImage; 
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [background release];
    [super dealloc];
}


@end
