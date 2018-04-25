#import "WPNoResultsView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide.h"
#import "WPNUXUtility.h"
#import "WPFontManager.h"
#import "WPDeviceIdentification.h"


@interface WPNoResultsView ()
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UITextView    *messageTextView;
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

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    self.delegate = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    [self configureTitleLabel];
    [self configureMessageLabel];
    [self configureButton];
}

- (void)configureTitleLabel
{
    _titleLabel                 = [[UILabel alloc] init];
    _titleLabel.numberOfLines   = 0;
    [self addSubview:_titleLabel];
}

- (void)configureMessageLabel
{
    _messageTextView                 = [[UITextView alloc] init];
    _messageTextView.font            = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _messageTextView.textColor       = [WPStyleGuide allTAllShadeGrey];
    _messageTextView.backgroundColor = [UIColor clearColor];
    _messageTextView.textAlignment   = NSTextAlignmentCenter;
    _messageTextView.adjustsFontForContentSizeCategory = YES;
    _messageTextView.editable = NO;
    _messageTextView.selectable = NO;
    _messageTextView.textContainerInset = UIEdgeInsetsZero;
    _messageTextView.textContainer.lineFragmentPadding = 0;
    [self addSubview:_messageTextView];
}

- (void)configureButton
{
    _button                     = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.titleLabel.font     = [WPStyleGuide subtitleFontBold];
    _button.hidden              = YES;
    [_button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [_button setBackgroundImage:[self newButtonBackgroundImage] forState:UIControlStateNormal];
    [self addSubview:_button];
}

- (void)didMoveToSuperview
{
    [self centerInSuperview];
}

- (void)layoutSubviews {

    CGFloat width = 280.0f;
    
    [self hideAccessoryViewIfNecessary];
    
    // Layout views
    _accessoryView.frame = CGRectMake((width - CGRectGetWidth(_accessoryView.frame)) / 2, 0, CGRectGetWidth(_accessoryView.frame), CGRectGetHeight(_accessoryView.frame));
    
    CGSize titleSize = [_titleLabel.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName: _titleLabel.font}
                                                      context:nil].size;

    _titleLabel.frame = CGRectMake(0.0f, (CGRectGetMaxY(_accessoryView.frame) > 0 && _accessoryView.hidden != YES ? CGRectGetMaxY(_accessoryView.frame) + 10.0 : 0) , width, titleSize.height);
    
    CGSize messageSize = [_messageTextView.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName: _messageTextView.font}
                                                          context:nil].size;

    _messageTextView.frame = CGRectMake(0.0f, CGRectGetMaxY(_titleLabel.frame) + 8.0, width, messageSize.height);
    
    [_button sizeToFit];
    CGSize buttonSize = _button.frame.size;
    buttonSize.width += 40.0;
    CGFloat buttonYOrigin = (CGRectGetHeight(_messageTextView.frame) > 0 ? CGRectGetMaxY(_messageTextView.frame) : CGRectGetMaxY(_titleLabel.frame)) + 17.0 ;
    _button.frame = CGRectMake((width - buttonSize.width) / 2, buttonYOrigin, MIN(buttonSize.width, width), buttonSize.height);
    
    
    CGRect bottomViewRect;
    if (_button != nil) {
        bottomViewRect = _button.frame;
    } else if (_messageTextView.text.length > 0) {
        bottomViewRect = _messageTextView.frame;
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

- (void)resetFonts
{
    self.titleText = self.titleLabel.text;
    self.button.titleLabel.font = [WPStyleGuide subtitleFontBold];
}

#pragma mark - Accessory View

/// Hide the accessory view in landscape orientation on iPhone to ensure entire view fits on screen
///
- (void)hideAccessoryViewIfNecessary
{
    UIDevice *device = [UIDevice currentDevice];
    self.accessoryView.hidden = (UIDeviceOrientationIsLandscape(device.orientation) && [WPDeviceIdentification isiPhone]);
}

#pragma mark Helper Methods

- (UIImage *)newButtonBackgroundImage {
    CGRect fillRect         = {0, 0, 11.0, 36.0};
    UIEdgeInsets capInsets  = {4, 4, 4, 4};
    
    UIGraphicsBeginImageContextWithOptions(fillRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context    = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [WPStyleGuide wordPressBlue].CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(fillRect, 1, 1)
                                                         cornerRadius:2.0].CGPath);
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
    return _messageTextView.text;
}

- (void)setMessageText:(NSString *)message {
    _messageTextView.text = message;
    [self setNeedsLayout];
}

- (NSAttributedString *)attributedMessageText
{
    return self.messageTextView.attributedText;
}

- (void)setAttributedMessageText:(NSAttributedString *)attributedMessageText
{
    NSAttributedString * finalAttributedText = [self applyMessageStylesToAttributedString:attributedMessageText];
    self.messageTextView.attributedText = finalAttributedText;
    self.messageTextView.selectable = YES;
}

- (NSAttributedString *)applyMessageStylesToAttributedString:(NSAttributedString *)attributedString
{
    NSRange fullTextRange = NSMakeRange(0, attributedString.string.length);
    NSMutableAttributedString *mutableAttributedText = [attributedString mutableCopy];

    [mutableAttributedText addAttribute:NSFontAttributeName value:self.messageTextView.font range:fullTextRange];
    [mutableAttributedText addAttribute:NSForegroundColorAttributeName value:self.messageTextView.textColor range:fullTextRange];

    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = self.messageTextView.textAlignment;
    [mutableAttributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullTextRange];

    return mutableAttributedText;
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
    
    title = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
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

        if ([self.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)self.superview;
            CGFloat headerHeight = (tableView.tableHeaderView == nil
                                    || tableView.tableHeaderView.hidden
                                    || tableView.tableHeaderView.alpha == 0.0) ? 0 : tableView.tableHeaderView.bounds.size.height;
            CGFloat footerHeight = (tableView.tableFooterView == nil
                                    || tableView.tableFooterView.hidden
                                    || tableView.tableFooterView.alpha == 0.0) ? 0 : tableView.tableFooterView.bounds.size.height;

            verticalOffset += (headerHeight + footerHeight);

            // Offset the frame's top if we have a header
            frame.origin.y = headerHeight;
        }

        // Sanity check to make sure the offsets are not set to large values
        frame.size.height = frame.size.height - verticalOffset > 0 ? frame.size.height - verticalOffset : frame.size.height;
        frame.size.width = frame.size.width - horizontalOffset > 0 ? frame.size.width - horizontalOffset : frame.size.width;
    }

    CGFloat x = (CGRectGetWidth(frame) - CGRectGetWidth(self.frame))/2.0;
    CGFloat y = (CGRectGetHeight(frame) / 2.0) - (CGRectGetHeight(self.frame) / 2.0) + frame.origin.y;

    frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

#pragma mark - Notification Hanlders

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self resetFonts];
    [self setNeedsLayout];
}

- (void)buttonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didTapNoResultsView:)]) {
        [self.delegate didTapNoResultsView:self];
    }
}

@end
