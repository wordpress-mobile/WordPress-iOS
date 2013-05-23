//
//  QuickPhotoButtonView.m
//  WordPress
//
//  Created by Eric Johnson on 6/19/12.
//

#import "QuickPhotoButtonView.h"
#import "Media.h"
#import "CircularProgressView.h"

@interface QuickPhotoButtonView () {
    UILabel *label;
    UIActivityIndicatorView *spinner;
    UIButton *button;
    CircularProgressView *progressView;
}

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) CircularProgressView *progressView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIButton *uploadingButton;

- (void)setup;
- (void)newQuickPhotoButtonTapped:(id)sender;
- (void)uploadingButtonTapped:(id)sender;
- (void)showProgress:(BOOL)show animated:(BOOL)animated delayed:(BOOL)delayed;

@end

@implementation QuickPhotoButtonView

@synthesize uploadingButton, spinner, button, delegate, progressView;

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
    [button addTarget:self action:@selector(newQuickPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setImage:[UIImage imageNamed:@"sidebar_camera"] forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setAdjustsImageWhenHighlighted:NO];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:button];

    
    
    self.uploadingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = self.bounds;
    frame.origin.y = self.bounds.size.height;
    uploadingButton.frame = frame;
    uploadingButton.titleLabel.textColor = [UIColor whiteColor];
    uploadingButton.titleLabel.shadowColor = [UIColor UIColorFromHex:0x000000 alpha:0.45f];
    uploadingButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0f);
    uploadingButton.titleLabel.lineBreakMode = UILineBreakModeClip;
    uploadingButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    uploadingButton.titleLabel.minimumFontSize = 12.0f;
    uploadingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [uploadingButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [uploadingButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
    [uploadingButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    [uploadingButton setTitle:NSLocalizedString(@"Uploading...", @"") forState:UIControlStateNormal];
    [uploadingButton addTarget:self action:@selector(uploadingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [uploadingButton setBackgroundColor:[UIColor clearColor]];
    [uploadingButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [uploadingButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [uploadingButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [uploadingButton setAdjustsImageWhenHighlighted:NO];
    
    uploadingButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:uploadingButton];
    
    CGRect rect;
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.autoresizingMask = UIViewAutoresizingNone;
    spinner.hidesWhenStopped = NO;
    rect = spinner.frame;

    [uploadingButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f + rect.size.width, 0.0f, 10.0f)];
    rect.origin.x = 6.0f;
    rect.origin.y = (self.frame.size.height - rect.size.height) / 2.0f;
    spinner.frame = rect;
    [uploadingButton addSubview:spinner];

    progressView = [[CircularProgressView alloc] init];
    progressView.color = [UIColor whiteColor];
    progressView.frame = rect;
    [uploadingButton addSubview:progressView];
    
    [self showProgress:NO animated:NO delayed:NO];
}


#pragma mark -
#pragma mark Instance Methods

- (void)newQuickPhotoButtonTapped:(id)sender {
    if (delegate) {
        [delegate quickPhotoButtonTapped:self];
    }
}

- (void)uploadingButtonTapped:(id)sender {
    if (delegate) {
        [delegate quickPhotoProgressButtonTapped:self];
    }
}

- (void)updateProgress:(float)progress {
    if (!spinner.isAnimating) return;
    
    if (progress < 1.0f) {
        self.progressView.hidden = NO;
        self.spinner.hidden = YES;
        self.progressView.progress = progress;
        uploadingButton.titleLabel.text = NSLocalizedString(@"Uploading...", @"");
    }
    else {
        self.progressView.hidden = YES;
        self.spinner.hidden = NO;
        uploadingButton.titleLabel.text = NSLocalizedString(@"Finalizing", @"");
    }
}

- (void)showSuccess {
    if (!spinner.isAnimating) return; // check the spinner to ensure we're showing progress.

    [UIView animateWithDuration:0.6f animations:^{
        spinner.hidden = YES;
        uploadingButton.enabled = NO;
        uploadingButton.titleLabel.text = NSLocalizedString(@"Published!", @"");
        uploadingButton.frame = CGRectMake(self.frame.origin.x, 0.0, self.frame.size.width, self.frame.size.height);
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
        spinner.hidden = NO;
        self.progressView.progress = 0;
        [spinner startAnimating];

        [UIView animateWithDuration:duration delay:delay options:0 animations:^{
            CGRect frame = button.frame;
            frame.origin.y = self.frame.size.height;
            button.frame = frame;
            
            frame = uploadingButton.frame;
            frame.origin.y = 0.0f;
            uploadingButton.frame = frame;
            
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
            
            frame = uploadingButton.frame;
            frame.origin.y = self.frame.size.height;
            uploadingButton.frame = frame;
            
        } completion:^(BOOL finished) {
            [spinner stopAnimating];

            CGRect frame = uploadingButton.frame;
            frame.origin.y = -frame.size.height;
            uploadingButton.frame = frame;
            uploadingButton.enabled = YES;
        }];
    }
}

@end
