#import "NoteBlockQuoteTableViewCell.h"
#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark NoteBlockTextTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockQuoteTableViewCell

- (NSInteger)numberOfLines
{
    NSInteger const NoteBlockLabelMaxLines = 4;
    return NoteBlockLabelMaxLines;
}

- (CGFloat)labelPreferredMaxLayoutWidth
{
    UIEdgeInsets const NoteBlockLabelInsets = {0.0f, 46.0f, 0.0f, 20.0f};
    return CGRectGetWidth(self.bounds) - NoteBlockLabelInsets.left - NoteBlockLabelInsets.right;
}

@end
