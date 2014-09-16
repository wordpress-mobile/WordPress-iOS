#import "WPNoResultsView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide.h"
#import "WPNUXUtility.h"
#import "WPFontManager.h"

@interface WPNoResultsView ()
@property (nonatomic, strong) UILabel   *titleLabel;
@property (nonatomic, strong) UILabel   *messageLabel;
@property (nonatomic, strong) UIButton  *button;
@end

@implementation WPNoResultsView

#pragma mark -
#pragma mark Lifecycle Methods

+ (instancetype)noResultsViewWithTitle:(NSString *)titleText message:(NSString *)messageText accessoryView:(UIView *)accessoryView buttonTitle:(NSString *)buttonTitle {
    
    WPNoResultsView *noResultsView  = [WPNoResultsView new];
    
    noResultsView.accessoryView     = accessoryView;
    noResultsView.titleText         = titleText;
    noResultsView.messageText       = messageText;
    noResultsView.buttonTitle       = buttonTitle;
    
    return noResultsView;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Title Label
        _titleLabel                 = [[UILabel alloc] init];
        _titleLabel.numberOfLines   = 0;
        
        // Message Label
        _messageLabel               = [[UILabel alloc] init];
        _messageLabel.font          = [WPFontManager openSansRegularFontOfSize:14.0];
        _messageLabel.textColor     = [WPStyleGuide allTAllShadeGrey];
        _messageLabel.numberOfLines = 0;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        
        // Button
        _button                     = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.titleLabel.font     = [WPStyleGuide regularTextFont];
        _button.hidden              = YES;
        [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
        [_button setBackgroundImage:[self newButtonBackgroundImage] forState:UIControlStateNormal];
        
        // Insert Subviews
        [self addSubview:_titleLabel];
        [self addSubview:_messageLabel];
        [self addSubview:_button];
        
        // Listen for orientation changes
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)didMoveToSuperview {
    [self centerInSuperview];
}

- (void)layoutSubviews {
    
    CGFloat width = 250.0f;
    
    // Layout views
    _accessoryView.frame = CGRectMake((width - CGRectGetWidth(_accessoryView.frame)) / 2, 0, CGRectGetWidth(_accessoryView.frame), CGRectGetHeight(_accessoryView.frame));
    
    CGSize titleSize = [_titleLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _titleLabel.font} context:nil].size;
    _titleLabel.frame = CGRectMake(0.0f, (CGRectGetMaxY(_accessoryView.frame) > 0 && _accessoryView.hidden != YES ? CGRectGetMaxY(_accessoryView.frame) + 10.0 : 0) , width, titleSize.height);
    
    CGSize messageSize = [_messageLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _messageLabel.font} context:nil].size;
    _messageLabel.frame = CGRectMake(0.0f, CGRectGetMaxY(_titleLabel.frame) + 8.0, width, messageSize.height);
    
    [_button sizeToFit];
    CGSize buttonSize = _button.frame.size;
    buttonSize.width += 40.0;
    CGFloat buttonYOrigin = (CGRectGetHeight(_messageLabel.frame) > 0 ? CGRectGetMaxY(_messageLabel.frame) : CGRectGetMaxY(_titleLabel.frame)) + 17.0 ;
    _button.frame = CGRectMake((width - buttonSize.width) / 2, buttonYOrigin, MIN(buttonSize.width, width), buttonSize.height);
    
    
    CGRect bottomViewRect;
    if (_button != nil) {
        bottomViewRect = _button.frame;
    } else if (_messageLabel.text.length > 0) {
        bottomViewRect = _messageLabel.frame;
    } else if (_titleLabel.text.length > 0) {
        bottomViewRect = _titleLabel.frame;
    } else {
        bottomViewRect = _accessoryView.frame;
    }
    
    CGRect viewFrame = CGRectMake(0, 0, width, CGRectGetMaxY(bottomViewRect));
    self.frame = viewFrame;
    
    if (self.superview) {
        [self centerInSuperview];
    }
}

#pragma mark Helper Methods

- (UIImage *)newButtonBackgroundImage {
    CGRect fillRect         = {0, 0, 11.0, 36.0};
    UIEdgeInsets capInsets  = {4, 4, 4, 4};
    
    UIGraphicsBeginImageContextWithOptions(fillRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context    = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [WPStyleGuide allTAllShadeGrey].CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(fillRect, 1, 1) cornerRadius:2.0].CGPath);
    CGContextStrokePath(context);
    
    UIImage *mainImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [mainImage resizableImageWithCapInsets:capInsets];
}


#pragma mark - Properties

- (NSString *)titleText {
    return _titleLabel.text;
}

- (void)setTitleText:(NSString *)title {
    if (title.length > 0) {
        _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:[WPNUXUtility titleAttributesWithColor:[WPStyleGuide whisperGrey]]];
    }
    [self setNeedsLayout];
}

- (NSString *)messageText {
    return _messageLabel.text;
}

- (void)setMessageText:(NSString *)message {
    _messageLabel.text = message;
    [self setNeedsLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView {
    if (accessoryView == _accessoryView) {
        return;
    }
    
    [_accessoryView removeFromSuperview];
    _accessoryView = accessoryView;
    
    if (accessoryView) {
        [self addSubview:accessoryView];
    }
    
    [self setNeedsLayout];
}

- (NSString *)buttonTitle {
    return [self.button titleForState:UIControlStateNormal];
}

- (void)setButtonTitle:(NSString *)title {
    self.button.hidden = (title.length == 0);
    
    if (title.length) {
        [self.button setTitle:title forState:UIControlStateNormal];
    }
    [self setNeedsLayout];
}


#pragma mark - Public Helpers

- (void)showInView:(UIView *)view {
    [view addSubview:self];
    [view bringSubviewToFront:self];
}

- (void)centerInSuperview {
    
    if (!self.superview) {
        return;
    }
    
    // Center in superview
    CGRect frame = [self superview].frame;
    
    // account for content insets of superview if it is a scrollview
    if ([self.superview.class isSubclassOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        
        CGFloat verticalOffset = scrollView.contentInset.top + scrollView.contentInset.bottom;
        CGFloat horizontalOffset =  scrollView.contentInset.left + scrollView.contentInset.right;
        
        // Sanity check to make sure the offsets are not set to large values
        frame.size.height = frame.size.height - verticalOffset > 0 ? frame.size.height - verticalOffset : frame.size.height;
        frame.size.width = frame.size.width - horizontalOffset > 0 ? frame.size.width - horizontalOffset : frame.size.width;
    }
    
    CGFloat x = (CGRectGetWidth(frame) - CGRectGetWidth(self.frame))/2.0;
    CGFloat y = ((CGRectGetHeight(frame)) - CGRectGetHeight(self.frame))/2.0;
    
    frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}


#pragma mark - Notification Hanlders

- (void)orientationDidChange:(NSNotification *)notification {
    
    // Hide the accessory view in landscape orientation on iPhone to ensure entire view fits on screen
    UIDevice *device        = notification.object;
    _accessoryView.hidden   = (UIDeviceOrientationIsLandscape(device.orientation) && IS_IPHONE);
    
    [self setNeedsLayout];
}

- (void)buttonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didTapNoResultsView:)]) {
        [self.delegate didTapNoResultsView:self];
    }
}

@end
