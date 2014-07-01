#import "NoteBlockTextTableViewCell.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "WPStyleGuide+Notifications.h"

#import <DTCoreText/DTCoreText.h>



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat const NoteBlockLabelWidthPad     = 560.0f;
static CGFloat const NoteBlockLabelWidthPhone   = 280.0f;
static UIEdgeInsets const NoteBlockLabelPadding = {4.0f, 0.0f, 4.0f, 0.0f};


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteBlockTextTableViewCell () <DTAttributedTextContentViewDelegate>
@property (nonatomic, weak) IBOutlet DTAttributedLabel  *attributedLabel;
@end


#pragma mark ====================================================================================
#pragma mark NoteBlockTextTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockTextTableViewCell

- (void)awakeFromNib
{
    NSAssert(self.attributedLabel, nil);
    
    [super awakeFromNib];
    
    self.backgroundColor                   = [WPStyleGuide notificationBlockBackgroundColor];
    self.selectionStyle                    = UITableViewCellSelectionStyleNone;
    
    self.attributedLabel.backgroundColor   = [UIColor clearColor];
    self.attributedLabel.numberOfLines     = 0;
    self.attributedLabel.delegate          = self;
}

- (void)setAttributedText:(NSAttributedString *)text
{
    // Force Layout: We need the right attributedLabel's width
    [self layoutIfNeeded];
    
    _attributedLabel.attributedString = text;
    _attributedLabel.layoutFrameHeightIsConstrainedByBounds = NO;
    
    // Manually update DTAttributedLabel's size
    CGRect frame            = _attributedLabel.frame;
    CGSize newSize          = [_attributedLabel suggestedFrameSizeToFitEntireStringConstraintedToWidth:CGRectGetWidth(frame)];
    frame.size              = newSize;
    _attributedLabel.frame  = frame;
    
    // Keep a reference!
    _attributedText         = text;
}


#pragma mark - DTAttributedTextContentViewDelegate

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView
                          viewForLink:(NSURL *)url
                           identifier:(NSString *)identifier
                                frame:(CGRect)frame
{
    DTLinkButton *linkButton                = [[DTLinkButton alloc] initWithFrame:frame];
    linkButton.URL                          = url;
    linkButton.showsTouchWhenHighlighted    = NO;
    [linkButton addTarget:self action:@selector(buttonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return linkButton;
}

- (void)buttonWasPressed:(DTLinkButton *)sender
{
    if (![sender isKindOfClass:[DTLinkButton class]] || !self.onUrlClick) {
        return;
    }
    
    self.onUrlClick(sender.URL);
}


#pragma mark - NoteBlockTableViewCell Methods

+ (CGFloat)heightWithText:(NSString *)text
{
    CGRect bounds                           = CGRectZero;
    bounds.size.width                       = IS_IPAD ? NoteBlockLabelWidthPad : NoteBlockLabelWidthPhone;
    bounds.size.height                      = CGFLOAT_HEIGHT_UNKNOWN;

    NSDictionary *attributes                = [WPStyleGuide notificationBlockAttributes];
    NSAttributedString *attributedString    = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    DTCoreTextLayouter *layouter            = [[DTCoreTextLayouter alloc] initWithAttributedString:attributedString];
	DTCoreTextLayoutFrame *tmpLayoutFrame   = [layouter layoutFrameWithRect:bounds range:NSMakeRange(0, 0)];
    CGFloat height                          = CGRectGetMaxY(tmpLayoutFrame.frame) + NoteBlockLabelPadding.top + NoteBlockLabelPadding.bottom;

    return height;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
