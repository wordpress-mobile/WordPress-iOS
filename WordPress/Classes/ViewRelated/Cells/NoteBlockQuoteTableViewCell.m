#import "NoteBlockQuoteTableViewCell.h"
#import "WPStyleGuide+Notifications.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSInteger const NoteBlockLabelMaxLines   = 4;
static CGFloat const NoteBlockLabelWidthPad     = 522.0f;
static CGFloat const NoteBlockLabelWidthPhone   = 254.0f;
static UIEdgeInsets const NoteBlockLabelPadding = {4.0f, 0.0f, 4.0f, 0.0f};


#pragma mark ====================================================================================
#pragma mark NoteBlockTextTableViewCell
#pragma mark ====================================================================================

@implementation NoteBlockQuoteTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSAssert(self.attributedLabel, nil);
    self.attributedLabel.numberOfLines = NoteBlockLabelMaxLines;
}


#pragma mark - NoteBlockTableViewCell Methods

+ (CGFloat)heightWithText:(NSString *)text
{
    CGRect bounds                           = CGRectZero;
    bounds.size.width                       = IS_IPAD ? NoteBlockLabelWidthPad : NoteBlockLabelWidthPhone;
    bounds.size.height                      = CGFLOAT_HEIGHT_UNKNOWN;
    
    NSDictionary *attributes                = [WPStyleGuide notificationBlockAttributesRegular];
    NSAttributedString *attributedString    = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    DTCoreTextLayouter *layouter            = [[DTCoreTextLayouter alloc] initWithAttributedString:attributedString];
	DTCoreTextLayoutFrame *tmpLayoutFrame   = [layouter layoutFrameWithRect:bounds range:NSMakeRange(0, 0)];
    tmpLayoutFrame.numberOfLines            = NoteBlockLabelMaxLines;
    CGFloat height                          = CGRectGetMaxY(tmpLayoutFrame.frame) + NoteBlockLabelPadding.top + NoteBlockLabelPadding.bottom;
        
    return height;
}

@end
