#import "WPUploadStatusView.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

@interface WPUploadStatusView() {
    UIButton *_uploadMediaButton;
    UIActivityIndicatorView *_activityIndicator;
}

@end

CGFloat const WPUploadStatusViewOffset = 8.0;

@implementation WPUploadStatusView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeControls];
    }
    return self;
}

#pragma mark - Private Methods

- (void)initializeControls
{
    _uploadMediaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _uploadMediaButton.frame = CGRectMake(0.0f, 0.0f, 200.0f, 33.0f);
    _uploadMediaButton.titleLabel.textColor = [UIColor whiteColor];
    _uploadMediaButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _uploadMediaButton.autoresizingMask = UIViewAutoresizingNone;
    [_uploadMediaButton addTarget:self action:@selector(tappedUploadText) forControlEvents:UIControlEventTouchUpInside];
    [_uploadMediaButton setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", nil)];
    [_uploadMediaButton setTitle:NSLocalizedString(@"Uploading Media...", nil) forState:UIControlStateNormal];
    _uploadMediaButton.titleLabel.font = [WPFontManager openSansBoldFontOfSize:14.0];
    _uploadMediaButton.backgroundColor = [UIColor clearColor];
    [_uploadMediaButton sizeToFit];
    [self addSubview:_uploadMediaButton];
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activityIndicator.autoresizingMask = UIViewAutoresizingNone;
    [_activityIndicator startAnimating];
    [_activityIndicator sizeToFit];
    [self addSubview:_activityIndicator];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedActivityIndicator)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [_activityIndicator addGestureRecognizer:tapGestureRecognizer];
}

- (void)tappedUploadText
{
    if (self.tappedView) {
        self.tappedView();
    }
}

- (void)tappedActivityIndicator
{
    if (self.tappedView) {
        self.tappedView();
    }
}

- (void)layoutSubviews
{
    CGFloat x = floor((CGRectGetWidth(self.bounds) - CGRectGetWidth(_uploadMediaButton.frame) - CGRectGetWidth(_activityIndicator.frame) - WPUploadStatusViewOffset)/2.0);
    CGFloat y = floor((CGRectGetHeight(self.bounds) - CGRectGetHeight(_uploadMediaButton.frame))/2.0);
    _uploadMediaButton.frame = CGRectMake(x, y, CGRectGetWidth(_uploadMediaButton.frame), CGRectGetHeight(_uploadMediaButton.frame));
    
    y = CGRectGetMinY(_uploadMediaButton.frame) + floor((CGRectGetHeight(_uploadMediaButton.frame) - CGRectGetHeight(_activityIndicator.frame))/2.0);
    _activityIndicator.frame = CGRectMake(CGRectGetMaxX(_uploadMediaButton.frame) + WPUploadStatusViewOffset, y, CGRectGetWidth(_activityIndicator.frame), CGRectGetHeight(_activityIndicator.frame));
    
    [super layoutSubviews];
}

@end
