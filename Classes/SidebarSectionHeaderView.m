/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import "SidebarSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#define DETAIL_LEDGE 44.0f //Fixme: this is already defined in PanelNavigationController.m

@interface SidebarSectionHeaderView ()

-(UIImage *)addText:(UIImage *)img text:(NSString *)text1;

@end
    
    
@implementation SidebarSectionHeaderView


@synthesize titleLabel=_titleLabel, disclosureButton=_disclosureButton, delegate=_delegate, sectionInfo=_sectionInfo, numberOfCommentsImageView=_numberOfCommentsImageView, blog = _blog;


+ (Class)layerClass {
    
    return [CAGradientLayer class];
}


-(id)initWithFrame:(CGRect)frame blog:(Blog*)blog sectionInfo:(SectionInfo *)sectionInfo delegate:(id <SidebarSectionHeaderViewDelegate>)delegate {
    
    self = [super initWithFrame:frame];
    
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
        CGRect titleLabelFrame = self.bounds;
        titleLabelFrame.origin.x += 51.0;
        if ( numberOfPendingComments > 0 ) 
            titleLabelFrame.size.width -= 102.0;
        else
            titleLabelFrame.size.width -= 51.0;
        
        titleLabelFrame.size.width -= DETAIL_LEDGE;
        
        CGRectInset(titleLabelFrame, 0.0, 6.0);
        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        
        //set the title of the blog        
        NSString *blogName = blog.blogName;
        if (blogName != nil && ! [@"" isEqualToString: [blogName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
            label.text = blogName;
        else
            label.text = [blog hostURL];            
        
        label.font = [UIFont boldSystemFontOfSize:17.0];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _titleLabel = label;
        
        UIImageView *commentsIconImgView = [[[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width - ( 35.0 + DETAIL_LEDGE ), 6.0, 35.0, 35.0)] autorelease];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [self addText:[UIImage imageNamed:@"inner-shadow.png"] text:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            commentsIconImgView.image = img;
        }
        [self addSubview:commentsIconImgView];
        _numberOfCommentsImageView = commentsIconImgView;
        
        // Create and configure the disclosure button.
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(self.frame.size.width - 31.0, 6.0, 35.0, 35.0);
        [button setImage:[UIImage imageNamed:@"carat.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"carat-open.png"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        _disclosureButton = button;
        
        
        // Set the colors for the gradient layer.
        static NSMutableArray *colors = nil;
        if (colors == nil) {
            colors = [[NSMutableArray alloc] initWithCapacity:3];
            UIColor *color = nil;
            color = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
            color = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
            color = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
            [colors addObject:(id)[color CGColor]];
        }
        [(CAGradientLayer *)self.layer setColors:colors];
        [(CAGradientLayer *)self.layer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.48], [NSNumber numberWithFloat:1.0], nil]];
    }
    
    return self;
}


-(IBAction)toggleOpen:(id)sender {
    
    [self toggleOpenWithUserAction:YES];
}


//Add text to UIImage - ref: http://iphonesdksnippets.com/post/2009/05/05/Add-text-to-image-(UIImage).aspx
-(UIImage *)addText:(UIImage *)img text:(NSString *)text1{ 
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

-(void)toggleOpenWithUserAction:(BOOL)userAction {
    
    // Don't allow section to be collapsed if it is already open
    if (userAction && self.disclosureButton.selected)
        return;
    
    // Toggle the disclosure button state.
    self.disclosureButton.selected = !self.disclosureButton.selected;
    
    //change the comments icon
    if( self.disclosureButton.selected ) {
        self.numberOfCommentsImageView.image = nil;        
    } else {
        int numberOfPendingComments = [_blog numberOfPendingComments];
        if ( numberOfPendingComments > 0 ) {
            UIImage *img = [self addText:[UIImage imageNamed:@"inner-shadow.png"] text:[NSString stringWithFormat:@"%d", numberOfPendingComments]];
            self.numberOfCommentsImageView.image = img;
        } else {
            self.numberOfCommentsImageView.image = nil;
        }
        
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




@end
