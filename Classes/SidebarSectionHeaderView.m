/*
 Custom header view for sidebar panel
 Based on example app from Apple at: 
 http://developer.apple.com/library/ios/#samplecode/TableViewUpdates/Introduction/Intro.html
*/

#import "SidebarSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"

@implementation SidebarSectionHeaderView


@synthesize titleLabel=_titleLabel, disclosureButton=_disclosureButton, delegate=_delegate, section=_section;


+ (Class)layerClass {
    
    return [CAGradientLayer class];
}


-(id)initWithFrame:(CGRect)frame blog:(Blog*)blog section:(NSInteger)sectionNumber delegate:(id <SidebarSectionHeaderViewDelegate>)delegate {
    
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        
        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];
        
        _delegate = delegate;        
        self.userInteractionEnabled = YES;
        
        UIImageView *blavatarView = [[[UIImageView alloc] initWithFrame:CGRectMake(6.0, 6.0, 35.0, 35.0)] autorelease];
        [blavatarView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        blavatarView.layer.cornerRadius = 4.0f;
        blavatarView.layer.masksToBounds = NO;
        blavatarView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0f, 0.0f, 35.0f, 35.0f) cornerRadius:4.0f].CGPath;
        blavatarView.layer.shouldRasterize = YES;
        blavatarView.layer.shadowOpacity = 0.33f;
        blavatarView.layer.shadowRadius = 2.0f;
        blavatarView.layer.shadowOffset = CGSizeZero;
        blavatarView.opaque = YES;
        [self addSubview:blavatarView];
        
        // Create and configure the title label.
        _section = sectionNumber;
        CGRect titleLabelFrame = self.bounds;
        titleLabelFrame.origin.x += 51.0;
        titleLabelFrame.size.width -= 51.0;
        CGRectInset(titleLabelFrame, 0.0, 6.0);
        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        label.text = blog.blogName;
        label.font = [UIFont boldSystemFontOfSize:17.0];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _titleLabel = label;
        
        
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


-(void)toggleOpenWithUserAction:(BOOL)userAction {
    
    // Don't allow section to be collapsed if it is already open
    if (userAction && self.disclosureButton.selected)
        return;
    
    // Toggle the disclosure button state.
    self.disclosureButton.selected = !self.disclosureButton.selected;
    
    // If this was a user action, send the delegate the appropriate message.
    if (userAction) {
        if (self.disclosureButton.selected) {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [self.delegate sectionHeaderView:self sectionOpened:self.section];
            }
        }
        /*else {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [self.delegate sectionHeaderView:self sectionClosed:self.section];
            }
        }*/
    }
}




@end
