#import "NoteBlockTextTableViewCell.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteBlockTextTableViewCell () <DTAttributedTextContentViewDelegate>
@property (nonatomic, weak) IBOutlet DTAttributedLabel *attributedLabel;
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
    self.attributedLabel.numberOfLines     = self.numberOfLines;
    self.attributedLabel.delegate          = self;
    self.attributedLabel.layoutFrameHeightIsConstrainedByBounds = NO;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Manually update DTAttributedLabel's size
    CGRect frame                = _attributedLabel.frame;
    CGFloat perferredLabelWidth = self.labelPreferredMaxLayoutWidth;
    CGSize newSize              = [_attributedLabel suggestedFrameSizeToFitEntireStringConstraintedToWidth:perferredLabelWidth];
    frame.size                  = newSize;
    _attributedLabel.frame      = frame;
}


#pragma mark - Helper Methods: Override if needed

- (NSInteger)numberOfLines
{
    return 0;
}

- (CGFloat)labelPreferredMaxLayoutWidth
{
    UIEdgeInsets const NoteBlockLabelInsets = {0.0f, 20.0f, 0.0f, 20.0f};
    return CGRectGetWidth(self.bounds) - NoteBlockLabelInsets.left - NoteBlockLabelInsets.right;
}


#pragma mark - Properties

- (void)setAttributedText:(NSAttributedString *)text
{
    _attributedText                                         = text;
    _attributedLabel.attributedString                       = text;
    _attributedLabel.layoutFrameHeightIsConstrainedByBounds = NO;
    [self setNeedsLayout];
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

@end
