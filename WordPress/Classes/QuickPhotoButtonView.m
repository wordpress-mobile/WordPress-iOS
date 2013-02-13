//
//  QuickPhotoButtonView.m
//  WordPress
//
//  Created by Eric Johnson on 6/19/12.
//

#import "QuickPhotoButtonView.h"

@interface QuickPhotoButtonView () {
    UILabel *label;
    UIActivityIndicatorView *spinner;
    UIButton *button;
}

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIButton *button;

- (void)setup;
- (void)handleButtonTapped:(id)sender;
- (void)showProgress:(BOOL)show animated:(BOOL)animated delayed:(BOOL)delayed;

@end

@implementation QuickPhotoButtonView

@synthesize label, spinner, button, delegate;

#pragma mark -
#pragma mark LifeCycle Methods



- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.shadowColor = [UIColor UIColorFromHex:0x000000 alpha:0.45f];
    button.titleLabel.shadowOffset = CGSizeMake(0, -1.0f);
    button.titleLabel.lineBreakMode = UILineBreakModeClip;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumFontSize = 12.0f;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [button setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
    [button setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    [button setTitle:NSLocalizedString(@"Photo", @"") forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setImage:[UIImage imageNamed:@"sidebar_camera"] forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setAdjustsImageWhenHighlighted:NO];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:button];
    
    CGRect rect;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.autoresizingMask = UIViewAutoresizingNone;
    spinner.hidesWhenStopped = YES;
    rect = spinner.frame;
    
    rect.origin.x = self.frame.origin.x + 6.0f;
    rect.origin.y = (self.frame.size.height - rect.size.height) / 2.0f;
    spinner.frame = rect;
    [self addSubview:spinner];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:(15.0f)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;

    label.frame = CGRectMake((spinner.frame.origin.x + spinner.frame.size.width + 6.0f), 0.0, (self.frame.size.width - spinner.frame.origin.x - spinner.frame.size.width), self.frame.size.height);
    label.text = NSLocalizedString(@"Uploading...", @"");
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumFontSize = 12.0f;
    label.shadowColor = [UIColor UIColorFromHex:0x000000 alpha:0.45f];
    label.shadowOffset = CGSizeMake(0, -1.0f);
    [self addSubview:label];
    
    [self showProgress:NO animated:NO delayed:NO];
}


#pragma mark -
#pragma mark Instance Methods

- (void)handleButtonTapped:(id)sender {
    if (delegate) {
        [delegate quickPhotoButtonViewTapped:self];
    }
}

- (void)showSuccess {
    if (!spinner.isAnimating) return; // check the spinner to ensure we're showing progress.
    
    [UIView animateWithDuration:0.6f animations:^{
        spinner.alpha = 0.0f;
        label.text = NSLocalizedString(@"Published!", @"");
        label.font = [UIFont boldSystemFontOfSize:(15.0f)];
        label.textAlignment = UITextAlignmentCenter;
        label.frame = CGRectMake(self.frame.origin.x, 0.0, self.frame.size.width, self.frame.size.height);
        label.textColor = [UIColor UIColorFromRGBAColorWithRed:200.0f green:228.0f blue:125.0f alpha:1.0f];
    } completion:^(BOOL finished) {
        [self showProgress:NO animated:YES delayed:YES];
    }];
}

- (void)showProgress:(BOOL)show animated:(BOOL)animated {
    [self showProgress:show animated:animated delayed:NO];
}

- (void)showProgress:(BOOL)show animated:(BOOL)animated delayed:(BOOL)delayed {
    CGFloat duration = 0.0f;
    CGFloat delay = 0.0f;
    if (animated) {
        duration = 0.6f;
    }
    if (delayed) {
        delay = 1.2f;
    }
    
    if (show) {
        spinner.alpha = 1.0f;
        [spinner startAnimating];
        label.hidden = NO;
        
        [UIView animateWithDuration:duration delay:delay options:0 animations:^{
            CGRect frame = button.frame;
            frame.origin.y = self.frame.size.height;
            button.frame = frame;
            
            frame = spinner.frame;
            frame.origin.y = (self.frame.size.height - frame.size.height) / 2.0f;
            spinner.frame = frame;
            
            frame = label.frame;
            frame.origin.y = 0.0f;
            label.frame = frame;
            
        } completion:^(BOOL finished) {
            // reposition above so we're always sliding down.
            button.hidden = YES;
            CGRect frame = button.frame;
            frame.origin.y = -frame.size.height;
            button.frame = frame;
        }];

    } else {
        button.hidden = NO;
        
        [UIView animateWithDuration:duration delay:delay options:0 animations:^{
            CGRect frame = button.frame;
            frame.origin.y = 0.0f;
            button.frame = frame;
            
            frame = spinner.frame;
            frame.origin.y = self.frame.size.height;
            spinner.frame = frame;
            
            frame = label.frame;
            frame.origin.y = self.frame.size.height;
            label.frame = frame;
            
        } completion:^(BOOL finished) {
            CGRect frame = spinner.frame;
            frame.origin.y = -frame.size.height;
            spinner.frame = frame;
            [spinner stopAnimating];
            
            frame = label.frame;
            frame.origin.y = -frame.size.height;
            label.frame = frame;

            label.hidden = YES;
            label.textColor = [UIColor whiteColor];
            label.frame = CGRectMake((spinner.frame.origin.x + spinner.frame.size.width + 6.0f), 0.0, (self.frame.size.width - spinner.frame.origin.x - spinner.frame.size.width), self.frame.size.height);
            label.textAlignment = UITextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:(15.0f)];
            label.text = NSLocalizedString(@"Uploading...", @"");
        }];
    }
}

@end
