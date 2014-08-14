#import "NoteBlockTableViewCell.h"



#pragma mark ====================================================================================
#pragma mark NoteBlockTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockTableViewCell

- (CGFloat)heightForWidth:(CGFloat)width
{
    // Setup the cell with the given width
    self.bounds = CGRectMake(0.0f, 0.0f, width, CGRectGetHeight(self.bounds));
    
    // Force layout
    [self layoutIfNeeded];
    
    // Calculate the height: There is an ugly bug where the calculated height might be off by 1px, thus, clipping the text
    CGFloat const NoteCellHeightPadding = 1;
    
    // iPad: Limit the width
    CGFloat cappedWidth = IS_IPAD ? WPTableViewFixedWidth : width;
    CGSize size = [self.contentView systemLayoutSizeFittingSize:CGSizeMake(cappedWidth, 0.0f)];
    
    return ceil(size.height) + NoteCellHeightPadding;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
